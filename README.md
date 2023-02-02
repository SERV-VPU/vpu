# Vector Processing Unit -VPU

Includes an altered version of the SERV core (https://github.com/olofk/serv)

This repository contains a fusesoc (https://github.com/olofk/fusesoc) environment with our Vector Processing Unit and a SERV implementation that has been modified to utilise it.

Vector extension unit for the SERV, to run SERV with the VPU add "--flag==vpu" in the fusesoc command line.  
For example:  
` $ fusesoc run --target=verilator_tb --flag=vpu servant --uart_baudrate=91000 --firmware=program.hex`  

The VPU currently supports loads, stores, and arithmetic instructions.  
There is currently an alignment issue with some of the store instructions, and also some problems with our SERV modifications that cause certain programs to halt.  

As an example of the second issue a program which invokes the rand() function in the C standard library several times will eventually stop working. Or at the very least this was the behaviour exhibited when our benchmark program used random numbers.  



The VPU is contributed to by Ren Chen for the University of Southampton's Group Design Project's Group 41 in 2022.  

## Contact:
Ren Chen: rc7g18@soton.ac.uk / chenren76@hotmail.com  
