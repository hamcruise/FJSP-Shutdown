import intervals
BigM = 10000
class Machine:

    def __init__(self, id_machine, pidle, engergyS, TB):
        self.__id_machine = id_machine
        self.__pidle = pidle
        self.__engergyS = engergyS
        self.__TB = TB
        self.cMAX = 0
        self.idle_intervals = [intervals.closed(0,BigM)]
        self.shutdown = 3
    def __str__(self):
        output = "Machine " + str(self.__id_machine)
        return output

    def id_machine(self):
        return self.__id_machine

    def pidle(self):
        return self.__pidle

    def engergyS(self):
        return self.__engergyS

    def TB(self):
        return self.__TB

