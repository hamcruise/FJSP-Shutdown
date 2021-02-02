int nbProcess = ...;
int nbJobs = ...;
int nbMchs = ...;
range Mchs = 1..nbMchs; 
range Opss = 1..nbProcess; 
range Jobs = 1..nbJobs; 
range Pos = 1..nbProcess*nbJobs; 
range Pos2 = 1..nbProcess*nbJobs-1; 

int Process1[Jobs] = ...;
int pidle[Mchs] = ...;
int EnergyS[Mchs] = ...;
int TB[Mchs] = ...;
int x[Mchs][Jobs][Opss] = ...;
int ptime[Mchs][Jobs][Opss] = ...;
float power1[Mchs][Jobs][Opss] = ...;
int P = 5;// common power
int N = 3; //max count of offs
int bM= 3*max(m in Mchs) sum(j in Jobs, o in Opss) ptime[m][j][o];
int a = 0;

tuple Operation {
  key int j; // Job id
  key int o;  // Operation id
} {Operation} Ops;
execute {
for(var j in Jobs) for(var o in Opss) Ops.add(j,o);
}	

tuple Mode {
  key int j; 
  key int o; 
  key int m; 
  int pt; //processing time
  int po; //power      
} {Mode} Modes;
execute {
for(var o in Ops) for(var m in Mchs) 
	if(x[m][o.j][o.o]==1)
   	   Modes.add(o.j, o.o, m,ptime[m][o.j][o.o],10*power1[m][o.j][o.o]); 
}	
	

execute  { cplex.tilim = 600;
}

int OOPairs[Ops][Ops];

execute {
  for(var o in Ops) for(var q in Ops){ 
    OOPairs[o][q]=0;
    if (o != q){
    for(var m in Mchs){ 
      if(x[m][o.j][o.o]==1 && x[m][q.j][q.o]==1){
        OOPairs[o][q]=1;
        break;    
      }
    }      
    if(a>0) OOPairs.add(o.j, o.o, q.j, q.o);    	
  }          
  }	    
}

// Position of last operation of job j
int jlast[j in Jobs] = max(o in Ops: o.j==j) o.o;
dvar boolean X[Modes];
dvar boolean W[Ops][Ops];
dvar boolean Z[Modes];
dvar boolean Q[Modes];
dvar float+ B[Ops];
dvar float+ E[Ops];
dvar float+ Idle[Ops];
dvar float+ Energy[Ops];
dvar float+ cmax;
dexpr float energy_common=cmax*P;
dexpr float energy_prod=sum(md in Modes) md.po*md.pt*X[md]/10;
dexpr float energy_idles=sum(o in Ops) Idle[o];
dexpr float energy_shutdown =sum(o in Ops) Energy[o] - energy_idles;

minimize energy_common + energy_prod + energy_idles + energy_shutdown;
//minimize energy_common ;
subject to {
  forall (o in Ops) sum(md in Modes: md.o==o.o && md.j==o.j) X[md]==1;
  forall (o in Ops)	E[o]==B[o] + sum(md in Modes: md.o==o.o && md.j==o.j) md.pt*X[md];
  forall (o,q in Ops: q.j==o.j && q.o==o.o+1) B[q]>=E[o];
  forall (o in Ops: o.o==jlast[o.j]) cmax >= E[o];

  forall (m in Mchs) sum(md in Modes: md.m==m) Q[md]<=1;
  forall (q in Ops) sum(o in Ops: OOPairs[o][q]>0) W[o][q]<=1;
  forall (o in Ops) sum(q in Ops: OOPairs[o][q]>0) W[o][q]+sum(md in Modes: md.j==o.j && md.o==o.o) Q[md]==1;
  
  forall (o,q in Ops, md1,md2 in Modes: q!=o && md1.j==o.j && md1.o==o.o && md2.j==q.j && md2.o==q.o && md1.m==md2.m) W[o][q]-1 <= X[md1]-X[md2];
  forall (o,q in Ops, md1,md2 in Modes: q!=o && md1.j==o.j && md1.o==o.o && md2.j==q.j && md2.o==q.o && md1.m==md2.m) X[md1]-X[md2] <= 1-W[o][q];
  forall (o,q in Ops: OOPairs[o][q]>0) sum(md1,md2 in Modes: md1.j==o.j && md1.o==o.o && md2.j==q.j && md2.o==q.o && md1.m==md2.m) X[md1] >= W[o][q];
  forall (o,q in Ops: OOPairs[o][q]>0) sum(md1,md2 in Modes: md1.j==o.j && md1.o==o.o && md2.j==q.j && md2.o==q.o && md1.m==md2.m) X[md2] >= W[o][q];
  forall (md in Modes) Q[md]<=X[md];
  forall (o,q in Ops: q!=o) B[q] >= E[o]+bM*(W[o][q]-1);
  forall (o in Ops) Idle[o] <= bM*(1-sum(md in Modes:md.j==o.j && md.o==o.o)Q[md]);
  forall (o,q in Ops: q!=o) Idle[o] <= B[q]-E[o]+bM*(1-W[o][q]);
  forall (o,q in Ops: q!=o) Idle[o] >= B[q]-E[o]-bM*(1-W[o][q]);
  forall (m in Mchs) sum(md in Modes: md.m==m) Z[md] <= N;
  
  forall (md in Modes, o in Ops: md.j==o.j && md.o==o.o) Idle[o] >=TB[md.m]*Z[md];
	
  forall (md in Modes, o in Ops: md.j==o.j && md.o==o.o) Energy[o] >= EnergyS[md.m] * Z[md];
  forall (md in Modes, o in Ops: md.j==o.j && md.o==o.o) Energy[o] >= pidle[md.m]*Idle[o] +bM*(X[md]-Z[md]-1);
  forall (md in Modes) Z[md]<=X[md];
  forall (md in Modes) Z[md]<=1-Q[md];
 }