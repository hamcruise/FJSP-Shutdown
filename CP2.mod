using CP;
int nbProcess = ...;
int nbJobs = ...;
int nbMchs = ...;
range Mchs = 1..nbMchs; 
range Opss = 1..nbProcess; 
range Jobs = 1..nbJobs; 

int Process1[Jobs] = ...;
int pidle[Mchs] = ...;
int EnergyS[Mchs] = ...;
int TB[Mchs] = ...;
int x[Mchs][Jobs][Opss] = ...;
int ptime[Mchs][Jobs][Opss] = ...;
float power1[Mchs][Jobs][Opss] = ...;
int P = 5;// common power
int N = 3; //max count of offs

tuple Operation {
  key int id; 
  key int jobId; // Job id
  key int opId;  // Operation id
} {Operation} Ops;
execute {
var k=1;
for(var j in Jobs) for(var o in Opss) Ops.add(k++,j,o);
}	

tuple Mode {
  key int id; 
  key int mch; 
  int pt; //processing time
  int po; //power      
} {Mode} Modes;
execute {
for(var o in Ops) for(var m in Mchs) 
	if(x[m][o.jobId][o.opId]==1)
   	   Modes.add(o.id,m,ptime[m][o.jobId][o.opId],10*power1[m][o.jobId][o.opId]); 
}	
int minP[m in Mchs] = min(md in Modes: md.mch==m) md.pt;
//int maxIdleCnt[m in Mchs] = sum(j in Jobs, o in Opss) x[m][j][o] ;
int maxIdleCnt = max(m in Mchs) sum(j in Jobs, o in Opss) x[m][j][o] ;

// Position of last operation of job j
int jlast[j in Jobs] = max(o in Ops: o.jobId==j) o.opId;
dvar interval shutdown[m in Mchs][1..N] optional in 0..900 size TB[m]..200;
dvar interval idle[m in Mchs][1..maxIdleCnt] optional in 0..900 size 0..200;

dvar interval ops[Ops] in 0..900; 
dvar interval modes[md in Modes] optional size md.pt;
dvar interval makespan[Mchs] optional in 0..900;

dvar sequence seqMchs[m in Mchs] 
 in    append(all(md in Modes: md.mch == m) modes[md],
              all(m in Mchs, i in 1..maxIdleCnt) idle[m][i],
              all(n in 1..N) 				shutdown[m][n])
 types append(all(md in Modes: md.mch == m) 	1,
 			  all(m in Mchs, i in 1..maxIdleCnt) 3,
	          all(n in 1..N) 					2);	 	           
dexpr int cmax=  max(j in Jobs, o in Ops: o.opId==jlast[j]) endOf(ops[o]);
dexpr int cmaxm[m in Mchs]=  max(md in Modes: md.mch==m) endOf(modes[md]);
dexpr float energy_common=cmax*P;
dexpr float energy_shutdown = sum(m in Mchs, n in 1..N) presenceOf(shutdown[m][n])*EnergyS[m];
dexpr float energy_prod=sum(md in Modes) md.po*sizeOf(modes[md])/10;                                                               
dexpr float energy_idles=sum(m in Mchs,i in 1..maxIdleCnt) pidle[m] * sizeOf(idle[m][i]);
execute {
  cp.param.TimeLimit = 300;
  cp.param.Workers = 4;
  cp.param.LogVerbosity=21;  
  cp.param.TemporalRelaxation = "On";
  cp.param.NoOverlapInferenceLevel = "Extended"  

 // var f = cp.factory; 	    
 // cp.setSearchPhases(f.searchPhase(ops)); 
}
minimize energy_common + energy_prod + energy_idles + energy_shutdown;
//minimize staticLex(cmax, energy_common + energy_prod + energy_idles + energy_shutdown);
subject to {
cmax==879;

  forall (m in Mchs, n in 1..N) {
  //Shutdown must be located between two production operations.
    presenceOf(shutdown[m][n]) => startOf(shutdown[m][n]) > startOf(makespan[m]) ;// + minP[m];	
    presenceOf(shutdown[m][n]) => endOf(shutdown[m][n])  <= endOf(makespan[m]) ;//- minP[m];
    presenceOf(shutdown[m][n]) => endOf(shutdown[m][n])  <= cmaxm[m];
  }
  forall(m in Mchs) sizeOf(makespan[m])== 
	 	sum(md in Modes: md.mch==m) sizeOf(modes[md]) +  
		sum(i in 1..maxIdleCnt) sizeOf(idle[m][i]) +
		sum(n in 1..N) sizeOf(shutdown[m][n]);

  forall(m in Mchs)
	span(makespan[m], all(md in Modes: md.mch==m) modes[md]);          
  forall (j in Jobs, o1 in Ops, o2 in Ops: o1.jobId==j && o2.jobId==j && o2.opId==1+o1.opId)
    endBeforeStart(ops[o1],ops[o2]);
  forall (o in Ops)
    alternative(ops[o], all(md in Modes: md.id==o.id) modes[md]);
  forall (m in Mchs)
    noOverlap(seqMchs[m]);
}
execute {
writeln("makespan        = ", cmax);
writeln("energy_common   = ", energy_common);
writeln("energy_prod     = ", energy_prod);
writeln("energy_idle     = ", energy_idles);
writeln("energy_shutdown = ", energy_shutdown);
writeln("energy_total    = ", energy_common + energy_prod + energy_idles + energy_shutdown);

writeln("m"+"\t"+"j"+"\t"+"o" +"\t"+ "pw" +"\t"+ "pt"+"\t"+ "s"+"\t"+ "e");
for (var md in Modes) for(var o in Ops) 
  if(modes[md].present && md.id==o.id)  
    writeln(md.mch + "\t" + o.jobId +"\t"+ o.opId +"\t"+ md.po +"\t" + md.pt  
    +"\t"+ modes[md].start  +"\t"+ modes[md].end);
writeln();
writeln("on/off schedule");
writeln("m"+"\t"+"s"+"\t"+ "e" +"\t"+ "dur");
for (var m in Mchs) for(var n=1;n<=N;n++) 
  if(shutdown[m][n].present)  
    writeln(m + "\t" + shutdown[m][n].start  +"\t"+ shutdown[m][n].end  +"\t"+ shutdown[m][n].size);
}