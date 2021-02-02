import sys
import numpy as np
import pickle
import time
import random
import copy

from Machine import Machine
from Operation import Operation
from Chromo import Chromo


class GA:
    def __init__(self, popsize, maxGen, crossoverRate, mutationRate):
        self.log = False
        self.popsize= popsize
        self.maxGen = maxGen
        self.crossoverRate = crossoverRate
        self.mutationRate = mutationRate
        self.fitnessList = []
        self.bestGene = 0
        self.bestMS = []
        self.bestOS = []
        self.MSlist = {}
        self.OSlist = {}

        for iter in range(popsize):
            self.MSlist[iter] = []
            self.OSlist[iter] = []

    def bestGeneUpdate(self):
        self.bestGene = self.fitnessList.index(min(self.fitnessList))

    def geneChange(self, geneIndex, MS, OS):
        gene = Chromo(MS, OS, nbMchs, nbJobs, nbProcess, operation_list, machine_list, self.log, out)
        gene.decoding
        fitness = gene.fitness
        self.MSlist[geneIndex][0] = MS
        self.OSlist[geneIndex][0] = OS
        self.fitnessList[geneIndex] = fitness

    def msMutation(self, individual):
        #print("msMutation individual: ", individual)
        for i in range(len(individual)) :
            current_machine = individual[i]
            job_index = i//nbProcess
            process_index = i % nbProcess
            operation = operation_list[job_index*nbProcess+process_index]
            if(len(operation.avail_ptimes)==0): continue
            min_machine_index = operation.avail_ptimes.index(min(operation.avail_ptimes))
            change_machine = operation.avail_machines[min_machine_index]
            #print(operation.avail_machines,",", operation.avail_ptimes, "," ,min_machine_index, "," , change_machine)
            if(current_machine != change_machine):
                #print(i,",", job_index, ",", process_index)
                #print("msMutation ", operation, ":" , current_machine, "-->", change_machine)
                individual[i] = change_machine
        return individual

    def osMutation(self, individual):
        #print("osMutation individual: ", individual)
        l = random.sample(range(0, len(individual)-1), 2)
        #print(l)
        l1 = l[0]
        l2 = l[1]
        p1 = individual[l1]
        p2 = individual[l2]
        individual[l1] = p2
        individual[l2] = p1
        #print("osMutation ", individual)
        return individual

    def osCrossover(self, p1, p2):
        print("p1: ",p1)
        print("p2: ",p2)
        c1 = copy.deepcopy(p1)
        c2 = copy.deepcopy(p2)

        jobSet1 = []
        jobSet2 = []
        while len(jobSet1) == 0 or len(jobSet2) == 0:
            jobSet1 = []
            jobSet2 = []
            for j in range(nbJobs):
                odd = random.randint(1, 100)
                if (odd <= 50):
                    jobSet1.append(j)
                else:
                    jobSet2.append(j)

        print("jobSet1 :",jobSet1)
        print("jobSet2 :",jobSet2)

        for i in range(len(jobSet1)):
            for j in range(nbProcess):
                p2.remove(jobSet1[i])

        for i in range(len(jobSet2)):
            for j in range(nbProcess):
                p1.remove(jobSet2[i])

        j = 0
        for i in range(len(c1)):
            if c1[i] in jobSet1: continue
            else :
                c1[i] = p2[j]
                j=j+1

        j=0
        for i in range(len(c2)):
            if c2[i] in jobSet2: continue
            else:
                c2[i] = p1[j]
                j = j + 1


        #print("c1: ",c1)
        #print("c2: ",c2)
        return c1, c2

    def msCrossover(self, p1, p2):
        print(p1)
        print(p2)
        odd = random.randint(1, 100)
        if(odd<=50):
            #print("uniform crossover!")
            l = random.sample(range(0, len(p1)-1), 2)
            #print(l)
            l1 = l[0]
            l2 = l[1]
            p1_1 = p1[l1]
            p1_2 = p1[l2]
            p2_1 = p2[l1]
            p2_2 = p2[l2]
            p1[l1] = p2_1
            p1[l2] = p2_2
            p2[l1] = p1_1
            p2[l2] = p1_2
        else:
            #print("two-point crossover!")
            l = sorted(random.sample(range(0, len(p1)-1), 2))
            #print(l)
            p1_s = p1[l[0]: l[1]+1]
            p2_s = p2[l[0]: l[1]+1]
            #print(p1_s)
            #print(p2_s)
            j = 0
            for i in range(l[0], l[1]+1):
                p1[i] = p2_s[j]
                p2[i] = p1_s[j]
                j = j+1
        return p1, p2

    def globalSelection(self, popsize, presize, nbMchs, nbJobs, nbProcess, operation_list):
        MSsize = nbJobs * nbProcess
        OSsize = nbJobs * nbProcess

        for iter in range(popsize):
            MS = []
            for i in range(MSsize):
                MS.append(-1)

            job_list = []
            for j in range(nbJobs):
                job_list.append(j)

            timeArray = []
            for m in range(nbMchs):
                timeArray.append(0)

            for i in range(nbJobs):
                #print(job_list)
                selectedJobIndex = random.sample(job_list, 1)[0]
                #print("selected Job", selectedJobIndex)
                job_list.remove(selectedJobIndex)
                for j in range(nbProcess):
                    operation = operation_list[selectedJobIndex*nbProcess+j]
                    #print("avail_machines:", operation.avail_machines)
                    if (len(operation.avail_machines) == 0): continue
                    addedTime = []
                    for m in range(len(operation.avail_machines)):
                        availMachineIndex = operation.avail_machines[m]
                        availMachinePtime = operation.avail_ptimes[m]
                        addedTime.append(timeArray[availMachineIndex] + availMachinePtime)
                    #print("addedTime: ", addedTime)
                    spt_machine_index = operation.avail_machines[addedTime.index(min(addedTime))]
                    #print("spt_machine_index: ", spt_machine_index)
                    timeArray[spt_machine_index] = timeArray[spt_machine_index] + operation.find_ptime(spt_machine_index)
                    MS[selectedJobIndex*nbProcess+j] = spt_machine_index
            self.MSlist[presize+iter].append(MS)

            OS = []
            job_list1 = []
            for j in range(nbJobs):
                for k in range(nbProcess):
                    job_list1.append(j)

            for i in range(OSsize):
                out = random.randint(0, len(job_list1) - 1)
                #print("Job Selection ", job_list[out])
                OS.append(job_list1[out])
                del job_list1[out]
            self.OSlist[presize+iter].append(OS)

    def localSelection(self, popsize, presize, nbMchs, nbJobs, nbProcess, operation_list):
        MSsize = nbJobs * nbProcess
        OSsize = nbJobs * nbProcess

        for iter in range(popsize):
            MS = []
            for i in range(MSsize):
                MS.append(-1)

            job_list = []
            for j in range(nbJobs):
                job_list.append(j)

            for i in range(nbJobs):
                #print(job_list)
                timeArray = []
                for m in range(nbMchs):
                    timeArray.append(0)
                selectedJobIndex = random.sample(job_list, 1)[0]
                #print("selected Job", selectedJobIndex)
                job_list.remove(selectedJobIndex)
                for j in range(nbProcess):
                    operation = operation_list[selectedJobIndex*nbProcess+j]
                    if (len(operation.avail_machines) == 0): continue
                    addedTime = []
                    for m in range(len(operation.avail_machines)):
                        availMachineIndex = operation.avail_machines[m]
                        availMachinePtime = operation.avail_ptimes[m]
                        addedTime.append(timeArray[availMachineIndex] + availMachinePtime)

                    spt_machine_index = operation.avail_machines[addedTime.index(min(addedTime))]
                    #print(addedTime, ":", spt_machine_index)
                    timeArray[spt_machine_index] = timeArray[spt_machine_index] + operation.find_ptime(spt_machine_index)
                    MS[selectedJobIndex*nbProcess+j] = spt_machine_index
            self.MSlist[presize+iter].append(MS)

            OS = []
            job_list1 = []
            for j in range(nbJobs):
                for k in range(nbProcess):
                    job_list1.append(j)

            for i in range(OSsize):
                out = random.randint(0, len(job_list1) - 1)
                #print("Job Selection ", job_list[out])
                OS.append(job_list1[out])
                del job_list1[out]
            self.OSlist[presize+iter].append(OS)


    def randomSelection(self, popsize, presize, nbMchs, nbJobs, nbProcess, operation_list):
        MSsize = nbJobs * nbProcess
        OSsize = nbJobs * nbProcess

        for iter in range(popsize):
            MS = []
            for i in range(MSsize):
                operation = operation_list[i]
                if (len(operation.avail_machines)==0) : 
                    MS.append(-1) #operation이 가능한 machine이 없음
                    continue
                #print(operation, operation.avail_machines)
                #print("Machine Selection ",operation.avail_machines[random.randint(0, len(operation.avail_machines)-1)])
                MS.append(operation.avail_machines[random.randint(0, len(operation.avail_machines)-1)])
            self.MSlist[presize+iter].append(MS)

            job_list = []
            for j in range(nbJobs):
                for k in range(nbProcess):
                    job_list.append(j)

            OS = []
            for i in range(OSsize):
                out = random.randint(0, len(job_list) - 1)
                #print("Job Selection ", job_list[out])
                OS.append(job_list[out])
                del job_list[out]
            self.OSlist[presize+iter].append(OS)

        #print([MSlist, OSlist])
        #return MSlist, OSlist


if __name__=='__main__':

    if len(sys.argv)<4:
        print("python GA.py [instance_name] [popsize] [maxGen] [crossoverRate] [mutationRate]")
        sys.exit()

    instance_name = sys.argv[1]
    popsize = int(sys.argv[2])
    maxGen = int(sys.argv[3])
    crossoverRate = int(sys.argv[4])
    mutationRate = int(sys.argv[5])

    #instance_name = "sfjs10"
    #popsize = 50
    #maxGen = 100
    #crossoverRate = 70
    #mutationRate = 10

    filename = instance_name + ".dat"+ ".pkl"
    outfile_name = instance_name+"-"+str(popsize)+"-"+str(maxGen)+"-"+str(crossoverRate)+"-"+str(mutationRate)+".txt"
    out = open(outfile_name, 'w')

    with open (filename, 'rb') as f:
        save_dict = pickle.load (f)

    nbProcess = save_dict[0]
    nbJobs = save_dict[1]
    nbMchs = save_dict[2]
    Process1 = save_dict[3]
    pidle = save_dict[4]
    EnergyS = save_dict[5]
    TB = save_dict[6]
    x = save_dict[7]
    ptime = save_dict[8]
    power1 = save_dict[9]

    print(nbProcess, nbJobs, nbMchs, Process1, pidle, EnergyS, TB, x, ptime, power1)

    machine_list= []
    for i in range(nbMchs):
        m = Machine(i, pidle[i], EnergyS[i], TB[i])
        machine_list.append(m)

    #print(machine_list[0].engergyS())

    #job_list = []
    #for i in range(nbJobs):
    #    j = Job(i)
    #    job_list.append(j)

    operation_list = []

    for j in range(nbJobs):
        for k in range(nbProcess):
            o = Operation(j, k)
            for i in range(nbMchs):
                if(x[i][j][k]!=0):
                    o.avail_machines.append(i)
                    o.avail_ptimes.append(ptime[i][j][k])
                    o.avail_power1s.append(power1[i][j][k])
            operation_list.append(o)

    start_time = time.time()

    ga = GA(popsize, maxGen, crossoverRate, mutationRate)

    #Initial population
    ga.globalSelection(int(ga.popsize * 0.6), 0, nbMchs, nbJobs, nbProcess, operation_list)
    ga.localSelection(int(ga.popsize * 0.3), int(ga.popsize * 0.6), nbMchs, nbJobs, nbProcess, operation_list)
    ga.randomSelection(ga.popsize - int(ga.popsize * 0.6) - int(ga.popsize * 0.3), int(ga.popsize * 0.6)+int(ga.popsize * 0.3), nbMchs, nbJobs, nbProcess, operation_list)

    for i in range(ga.popsize) :
        print("==========================Population [", i, "]========================")
        out = open(outfile_name, 'a')
        gene = Chromo(ga.MSlist[i][0], ga.OSlist[i][0], nbMchs, nbJobs, nbProcess, operation_list, machine_list, ga.log, out)
        gene.decoding
        #print(i," Obj :", gene.fitness)
        ga.fitnessList.append(gene.fitness)

    ga.bestGeneUpdate()
    print("BestGene :", ga.bestGene, "BestFitness :", ga.fitnessList[ga.bestGene], ga.fitnessList)

    for generation in range(ga.maxGen):
        print("==========================Generation [", generation, "]========================")
        #Crossover
        odd = random.randint(1, 100)
        if (odd <= ga.crossoverRate):
            #selection: 4-size tournament
            c1, c2, c3, c4 = random.sample(range(0, ga.popsize - 1), 4)
            if(ga.fitnessList[c1] < ga.fitnessList[c2]):
                p1Index = c1
            else : p1Index = c2

            if(ga.fitnessList[c3] < ga.fitnessList[c4]):
                p2Index = c3
            else : p2Index = c4

            print("Crossover ", ga.OSlist[p1Index][0], ",", ga.OSlist[p2Index][0])
            OS_c1, OS_c2 = ga.osCrossover(ga.OSlist[p1Index][0], ga.OSlist[p2Index][0])

            ga.geneChange(p1Index, ga.MSlist[p1Index][0], OS_c1)
            ga.geneChange(p2Index, ga.MSlist[p2Index][0], OS_c2)

        #Mutation
        odd = random.randint(1, 100)
        if (odd <= ga.mutationRate):
            selectedGeneIndex =  random.randint(0, ga.popsize-1)
            print("Mutation ", ga.MSlist[selectedGeneIndex][0], ",", ga.OSlist[selectedGeneIndex][0])
            msMutation = ga.msMutation(ga.MSlist[selectedGeneIndex][0])
            osMutation = ga.osMutation(ga.OSlist[selectedGeneIndex][0])

            ga.geneChange(selectedGeneIndex, msMutation, osMutation)

        ga.bestGeneUpdate()
        print("BestGene :", ga.bestGene, "BestFitness :", ga.fitnessList[ga.bestGene], ga.fitnessList)

    ga.log = True
    gene = Chromo(ga.MSlist[ga.bestGene][0], ga.OSlist[ga.bestGene][0], nbMchs, nbJobs, nbProcess, operation_list, machine_list, ga.log, out)
    gene.decoding
    Obj = gene.fitness
    print("Time: ", time.time() - start_time)
    if (ga.log == True): out.write("Obj: \t"+str(Obj) + "\tTime: \t" + str(time.time() - start_time) + "\n" )




