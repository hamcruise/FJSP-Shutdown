
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
//int bM = 9999;
int bM= 3*max(m in Mchs) sum(j in Jobs, o in Opss) ptime[m][j][o];

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
execute  { cplex.tilim = 5;
}

// Position of last operation of job j
int jlast[j in Jobs] = max(o in Ops: o.j==j) o.o;
dvar boolean X[Modes];
dvar boolean Y[Modes][Pos];
dvar boolean Z[Mchs][Pos];
dvar float+ B[Ops];
dvar float+ E[Ops];
dvar float+ S[Mchs][Pos];
dvar float+ F[Mchs][Pos];
dvar float+ Energy[Mchs][Pos];
dvar float+ Idle[Mchs][Pos];
dvar float+ cmax;
dexpr float energy_common=cmax*P;
dexpr float energy_prod=sum(md in Modes) md.po*md.pt*X[md]/10;
dexpr float energy_idles=sum(m in Mchs, t in Pos) Idle[m][t];
dexpr float energy_shutdown =sum(m in Mchs, t in Pos) Energy[m][t] - energy_idles;

minimize energy_common + energy_prod + energy_idles + energy_shutdown;
//minimize energy_common ;
subject to {
  forall (o in Ops)  sum(md in Modes: md.o==o.o && md.j==o.j) X[md]==1;
  forall (md in Modes) sum(t in Pos) Y[md][t]==X[md]; 
  forall (m in Mchs,t in Pos) sum(md in Modes: md.m==m) Y[md][t] <= 1;  
  forall (m in Mchs,t in Pos2) 
  	sum(md in Modes: md.m==m) Y[md][t] >= sum(md in Modes: md.m==m) Y[md][t+1];

  forall (o in Ops)	E[o]==B[o] + sum(md in Modes: md.o==o.o && md.j==o.j) md.pt*X[md];
  forall (m in Mchs,t in Pos)	F[m][t]==S[m][t] + sum(md in Modes: md.m==m) md.pt*Y[md][t];
  forall (m in Mchs, md in Modes,o in Ops, t in Pos: md.m==m && md.o==o.o && md.j==o.j) {
  	S[m][t] <= B[o] + bM*(1-Y[md][t]);
 	S[m][t] + bM*(1-Y[md][t]) >= B[o];
	}	
  forall (m in Mchs,t in Pos2) {	
//	S[m][t+1] - F[m][t] >= TB[m] - bM*(1-Z[m][t]);
//	S[m][t+1] - F[m][t] <= TB[m] + bM*(Z[m][t]);
	F[m][t] <=S[m][t+1];
	}
  forall (o1,o2 in Ops: o1.j==o2.j && o1.o+1==o2.o)	E[o1] <=B[o2];
  forall (o in Ops: o.o==jlast[o.j]) cmax >= E[o];
  forall (m in Mchs) sum(t in Pos) Z[m][t] <= N;
    
  /*forall (m in Mchs,t in Pos2) { 
	U[m][t+1] >= S[m][t+1] - bM*Z[m][t];
	U[m][t+1] <= S[m][t+1] + bM*Z[m][t];
	U[m][t+1] <= bM*(1-Z[m][t]);	
	}	
  forall (m in Mchs,t in Pos2) { 
	W[m][t] >= F[m][t] - bM*Z[m][t];
	W[m][t] <= F[m][t] + bM*Z[m][t];
	W[m][t] <= bM*(1-Z[m][t]);	
	}	*/
   forall(m in Mchs, t in Pos2) Energy[m][t] >= EnergyS[m] * Z[m][t];
   forall(m in Mchs, t in Pos2) Energy[m][t] >= (S[m][t+1] - F[m][t]) * pidle[m] -bM*Z[m][t];
   forall(m in Mchs, t in Pos2) Idle[m][t] >= (S[m][t+1] - F[m][t]) * pidle[m] -bM*Z[m][t];	     
 }