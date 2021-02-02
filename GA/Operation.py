class Operation:
    def __init__(self, id_job, id_operation):
        self.__id_job = id_job
        self.__id_operation = id_operation
        self.assigned_machine = -1
        self.avail_machines = []
        self.avail_ptimes = []
        self.avail_power1s = []
        self.allowable_start_time = 0
        self.earliest_start_time = 0
        self.earliest_complete_time = 0

    def __str__(self):
        output = "Operation : " + str(self.__id_job+1) + "-" + str(self.__id_operation+1)
        return output

    def id_operation(self):
        return self.__id_operation

    def id_job(self):
        return self.__id_job

    def find_ptime(self, machine_index):
        ptime = 0
        for i in range(len(self.avail_machines)):
            if(self.avail_machines[i]==machine_index): return self.avail_ptimes[i]
        return ptime

    def find_power1(self, machine_index):
        power1 = 0
        for i in range(len(self.avail_machines)):
            if(self.avail_machines[i]==machine_index): return self.avail_power1s[i]
        return power1
