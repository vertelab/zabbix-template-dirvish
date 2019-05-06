#!/usr/bin/python

def read_config():
    f = open('/etc/dirvish/master.conf','r')
    lines = f.read().split('\n')
    f.close()
    master = {}
    index = 0
    while index < len(lines):
        if 'bank' in lines[index]:
            index += 1
            master['bank'] = lines[index].strip()
        if 'Runall' in lines[index]:
            master['Runall'] = []
            index += 1
            while not (lines[index] == '\n' or lines[index] == ''):
                # ~ print lines[index],len(lines[index])
                if lines[index].split()[0][0] != '#':
                    master['Runall'].append(lines[index].split())
                index += 1
        index += 1
    return master
