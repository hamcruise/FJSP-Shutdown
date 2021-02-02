import copy
import intervals
BigM = 10000
class Chromo:
    def __init__(self, MS, OS, nbMchs, nbJobs, nbProcess, operation_list, machine_list, log, out):
        self.__MS = copy.deepcopy(MS)
        self.__OS = copy.deepcopy(OS)
        self.__nbMchs =  nbMchs
        self.__nbJobs = nbJobs
        self.__nbProcess = nbProcess
        self.__operation_list = copy.deepcopy(operation_list)
        self.__machine_list = copy.deepcopy(machine_list)
        self.log = log
        self.out = out

    @property
    def fitness(self): #Fitness evaluation
        nbMchs = self.__nbMchs
        operation_list = self.__operation_list
        machine_list = self.__machine_list
        P0 = 5
        Obj1 = 0
        Obj2 = 0
        Obj3 = 0
        Obj4 = 0

        for i in range(len(operation_list)):
            opp = operation_list[i]
            if (opp.assigned_machine != -1):
                Obj1 += opp.find_power1(opp.assigned_machine)*(opp.earliest_complete_time-opp.earliest_start_time)
                if (self.log == True):
                    self.out.write(str(opp) + "\tassigned machine\t" + str(
                        opp.assigned_machine + 1) + "\tinterval \t" + str(
                        opp.earliest_start_time) + "\t" + str(opp.earliest_complete_time) + "\n")

        cMAX = 0
        for m in range(nbMchs):
            machine = machine_list[m]
            if (self.log == True): self.out.write(str(machine) + "\t cMAX is\t" + str(machine.cMAX)+ "\n")
            for j in range(len(machine.idle_intervals)):
                interval = machine.idle_intervals[j]
                #print(interval)
                if (interval == intervals.empty()): continue
                ts = int(interval.lower)
                te = int(interval.upper)
                interval_len = te - ts
                if(ts == 0 or te == BigM) : continue
                else :
                    print("Idle time is ", machine ," interval [",ts, ",", te, "]")
                    if (self.log == True):  self.out.write("Idle time is \t"+str(machine)+"\t interval\t"+str(ts)+"\t"+str(te)+"\n")
                    if(interval_len >= machine.TB() and machine.shutdown > 0):
                        print("Shutdown :", machine)
                        if (self.log == True): self.out.write("Shutdown :\t" + str(machine)+"\n")
                        machine.shutdown -= 1
                        Obj3 += machine.engergyS()
                    else:
                        Obj2 += interval_len*machine.pidle()
            if (cMAX < machine.cMAX) : cMAX = machine.cMAX


        Obj4 +=P0*cMAX

        if (self.log == True):
            self.out.write("Total cMAX is\t" + str(cMAX)+ "\n")
            self.out.write("Energy Common is\t" + str(Obj4) + "\n")
            self.out.write("Energy Prod is\t" + str(Obj1) + "\n")
            self.out.write("Energy Idle is\t" + str(Obj2) + "\n")
            self.out.write("Energy Shutdown is\t" + str(Obj3) + "\n")

        print("Total Obj : ", Obj1+Obj2+Obj3+Obj4)
        return Obj1+Obj2+Obj3+Obj4

    @property
    def decoding(self):
        OS = self.__OS
        MS = self.__MS
        nbProcess = self.__nbProcess
        operation_list = self.__operation_list
        machine_list = self.__machine_list
        print("Chromo ", MS, ":", OS)
        if (self.log == True):  self.out.write("Chromo \t"+str(MS)+"\t"+str(OS)+"\n")
        for i in range(len(OS)):
            job_index = OS[i]
            process_index = OS[0:i].count(OS[i])
            operation = operation_list[job_index*nbProcess+process_index]
            machine_index = MS[job_index*nbProcess+process_index]
            machine = machine_list[machine_index]
            print(operation, machine_index+1,",", operation.find_ptime(machine_index))
            if(process_index != 0):
                prev_operation = operation_list[job_index*nbProcess+process_index-1]
                operation.allowable_start_time = prev_operation.earliest_complete_time
                #print("prev_operation: ", prev_operation, " updated! ", operation.allowable_start_time )

            if(machine.idle_intervals[len(machine.idle_intervals)-1].upper != BigM):
                print("add interval: ")
                machine.idle_intervals.append(intervals.closed(machine.cMAX, BigM))

            num_intervals = len(machine.idle_intervals)
            print("num_intervals: ", num_intervals)
            print(machine.idle_intervals)

            asij = operation.allowable_start_time
            tijk = operation.find_ptime(machine_index)
            cMAX = machine.cMAX
            for k in range(num_intervals):
                interval = machine.idle_intervals[k]
                #print("interval", interval)

                if (interval == intervals.empty()): continue
                ts = int(interval.lower)
                te = int(interval.upper)
                if(ts==te): continue
                if(te!=BigM):
                    if(max(ts, asij) + tijk <=te) :
                        operation.earliest_start_time = max(ts, asij)
                        operation.earliest_complete_time = operation.earliest_start_time + tijk
                        operation.assigned_machine = machine_index
                        #print(ts, "!!!", asij, "!!!", cMAX, "!!!", te)
                        print(operation, " insert machine", operation.assigned_machine+1, " interval [",
                              operation.earliest_start_time, ",", operation.earliest_complete_time, "]")

                        machine.idle_intervals = list(interval - intervals.closedopen(operation.earliest_start_time, operation.earliest_complete_time))
                        if (machine.cMAX < operation.earliest_complete_time): machine.cMAX = operation.earliest_complete_time
                        break

                else:
                    operation.earliest_start_time = max(asij, cMAX)
                    operation.earliest_complete_time = operation.earliest_start_time  + tijk
                    operation.assigned_machine = machine_index
                    #print(ts,"!!!",asij,"!!!",cMAX,"!!!",te)
                    print(operation," insert machine", operation.assigned_machine+1," interval [",operation.earliest_start_time,",",operation.earliest_complete_time,"]")
                    if (machine.cMAX < operation.earliest_complete_time): machine.cMAX = operation.earliest_complete_time


