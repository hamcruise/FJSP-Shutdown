
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
//int bM = 9999;
int bM= 3*max(m in Mchs) sum(j in Jobs, o in Opss) ptime[m][j][o];

int MchSlot[m in Mchs] = sum(j in Jobs, o in Opss) x[m][j][o];
//int MchSlot[m in Mchs]=36;
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

tuple ModeT {
  key int j; 
  key int o; 
  key int m; 
  int pt; //processing time
  int po; //power
  key int t; //slot 
        
} {ModeT} ModeTs;
execute {
for(var o in Ops) for(var m in Mchs) for(var t=1;t<=MchSlot[m];t++)
	if(x[m][o.j][o.o]==1)
   	   ModeTs.add(o.j, o.o, m,ptime[m][o.j][o.o],10*power1[m][o.j][o.o],t ); 
}	

tuple t_mt {
  key int m; 
  key int t; //slot 
} {t_mt} MT;
execute {
for(var m in Mchs) for(var t=1;t<=MchSlot[m];t++) MT.add(m,t); 
}


execute  { cplex.tilim = 30;}

// Position of last operation of job j
int jlast[j in Jobs] = max(o in Ops: o.j==j) o.o;
dvar boolean X[Modes];
dvar boolean Y[ModeTs];
dvar boolean Z[MT];
dvar float+ B[Ops];
dvar float+ E[Ops];
dvar float+ S[MT];
dvar float+ F[MT];
dvar float+ Energy[MT];
dvar float+ Idle[MT];
dvar float+ cmax;
dexpr float energy_common=cmax*P;
dexpr float energy_prod=sum(md in Modes) md.po*md.pt*X[md]/10;
dexpr float energy_idles=sum(mt in MT) Idle[mt];
dexpr float energy_shutdown = sum(mt in MT) Energy[mt] - energy_idles;
minimize energy_common + energy_prod + energy_idles + energy_shutdown;
subject to {
  forall (o in Ops)  sum(md in Modes: md.o==o.o && md.j==o.j) X[md]==1;
  forall (md in Modes) sum(mt in ModeTs:md.m==mt.m&& md.j==mt.j&& md.o==mt.o) Y[mt]==X[md];  
  forall (mt in MT) sum(md in ModeTs: mt.m==md.m && mt.t==md.t) Y[md] <= 1;  

  forall (mt in MT: mt.t < MchSlot[mt.m]) 
  	sum(md in ModeTs: md.m==mt.m && md.t==mt.t)   Y[md] >= 
  	sum(md in ModeTs: md.m==mt.m && md.t==mt.t+1) Y[md];

  forall (o in Ops)	E[o]==B[o] + sum(md in Modes: md.o==o.o && md.j==o.j) md.pt*X[md];
  forall (mt in MT)	F[mt]==S[mt] + sum(md in ModeTs: md.m==mt.m && md.t==mt.t) md.pt*Y[md];  
  forall (mt in MT, md in ModeTs, o in Ops: mt.m==md.m && mt.t==md.t && md.o==o.o && md.j==o.j) {
  	S[mt] <= B[o] + bM*(1-Y[md]);
 	S[mt] + bM*(1-Y[md]) >= B[o];
	}	
  forall (mt1,mt2 in MT: mt1.t < MchSlot[mt1.m] && mt1.m==mt2.m && mt1.t+1==mt2.t) 	
	F[mt1] <=S[mt2];

  forall (o1,o2 in Ops: o1.j==o2.j && o1.o+1==o2.o)	E[o1] <=B[o2];
  forall (o in Ops: o.o==jlast[o.j]) cmax >= E[o];
  forall (m in Mchs) sum(mt in MT: mt.m==m) Z[mt] <= N;  	    	   

  forall(mt in MT: mt.t < MchSlot[mt.m]) Energy[mt] >= EnergyS[mt.m] * Z[mt];
  forall(mt1,mt2 in MT: mt1.t < MchSlot[mt1.m] && mt1.m==mt2.m && mt1.t+1==mt2.t) Energy[mt1] >= (S[mt2] - F[mt1]) * pidle[mt1.m] -bM*Z[mt1];
  forall(mt1,mt2 in MT: mt1.t < MchSlot[mt1.m] && mt1.m==mt2.m && mt1.t+1==mt2.t) Idle[mt1] >= (S[mt2] - F[mt1]) * pidle[mt1.m] -bM*Z[mt1];
    
 }
