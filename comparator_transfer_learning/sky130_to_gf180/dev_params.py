#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 10 17:28:00 2023

@author: lizongh2

This script is used to generate block of spice commands that used to 
access BSIM4 device internal device parameters.

This one is for GF180MCU process (stack option C)

You can just run it once to generate the script for the DCOP
"""

from ckt_graphs import GraphDoubleTailComp, GraphStrongArmComp

class DeviceParams(object):
    def __init__(self, ckt_hierarchy, warning_msg=False):
        self.ckt_hierarchy = ckt_hierarchy
        self.dev_names_mos = (
            'nfet_03v3',
            'nfet_03v3_dss',
            'nfet_05v0',
            'nfet_06v0',
            'nfet_06v0_nvt',
            'pfet_03v3',
            'pfet_03v3_dss',
            'pfet_06v0',
            )
        self.dev_names_r = (
            'nplus_u',
            'npolyf_u',
            'pplus_u',
            'ppolyf_u',
            )
        self.dev_names_c = (
            'cap_mim_2p0fF',
            'cap_nmos_03v3',
            'cap_nmos_06v0',
            'cap_pmos_03v3',
            'cap_pmos_06v0',
            )
        
        if warning_msg == True:
            for i in self.ckt_hierarchy:
                dev_name = i[2]
                dev_type = i[3]
                if dev_type == 'm' or dev_type == 'M':
                    if dev_name not in self.dev_names_mos:
                        print(f'This MOS is not in GF180MCU PDK. A valid device name can be {self.dev_names_mos}.')    
                elif dev_type == 'r' or dev_type == 'R':
                    if dev_name not in self.dev_names_r:
                        print(f'This resistor is not in GF180MCU PDK. A valid device name can be {self.dev_names_r}.')    
                elif dev_type == 'c' or dev_type == 'C':
                    if dev_name not in self.dev_names_c:
                        print(f'This capacitor is not in GF180MCU PDK. A valid device name can be {self.dev_names_c}.')    
                elif dev_type == 'i' or dev_type == 'I':
                    None
                elif dev_type == 'v' or dev_type == 'V':
                    None
                else:
                    print('You have a device type that cannot be found here...')

        # 45 attributes for mos
        self.params_mos = (
            'gmbs',
            'gm',
            'gds',
            'vdsat',
            'vth',
            'id',
            'ibd',
            'ibs',
            'gbd',
            'gbs',
            'isub',
            'igidl',
            'igisl',
            'igs',
            'igd',
            'igb',
            'igcs',
            'vbs',
            'vgs',
            'vds',
            'cgg',
            'cgs',
            'cgd',
            'cbg',
            'cbd',
            'cbs',
            'cdg',
            'cdd',
            'cds',
            'csg',
            'csd',
            'css',
            'cgb',
            'cdb',
            'csb',
            'cbb',
            'capbd',
            'capbs',
            'qg',
            'qb',
            'qs',
            'qinv',
            'qdef',
            'gcrg',
            'gtau'
            )
        # 20 attributes for r
        self.params_r = (
            'r',
            'ac',
            'temp',
            'dtemp',
            'l',
            'w',
            'm',
            'tc',
            'tc1',
            'tc2',
            'scale',
            'noise',
            'i',
            'p',
            'sens_dc',
            'sens_real',
            'sens_imag',
            'sens_mag',
            'sens_ph',
            'sens_cplx'
            )
        # 18 attributes for c
        self.params_c = (
            'capacitance',
            'cap',
            'c',
            'ic',
            'temp',
            'dtemp',
            'w',
            'l',
            'm',
            'scale',
            'i',
            'p',
            'sens_dc',
            'sens_real',
            'sens_imag',
            'sens_mag',
            'sens_ph',
            'sens_cplx'
            )
        # 8 attributes for i source
        self.params_i = (
            'dc',
            'acmag',
            'acphase',
            'acreal',
            'acimag',
            'v',
            'p',
            'current'
            )
        # 7 attributes for v source
        self.params_v = (
            'dc',
            'acmag',
            'acphase',
            'acreal',
            'acimag',
            'i',
            'p',
            )
        
    def gen_dev_params(self, file_name):
        lines = []
        write_file = ''
        for i in self.ckt_hierarchy:
            symbol_name = i[0]
            subckt = i[1]
            dev_name = i[2]
            dev_type = i[3]

            if dev_type == 'm' or dev_type == 'M':
                for param in self.params_mos:
                    if subckt == '':
                        raise ValueError('In this PDK, transistor is instantiated as a subckt! Subckt is missing here.')
                    else:
                        if dev_name in self.dev_names_mos:
                            line = f'let {param}_{symbol_name}=@m.{subckt}.m0[{param}]'
                        else:
                            raise ValueError(f'This device {symbol_name} is not defined in this PDK.')
                    lines.append(line)
                    write_file = write_file + f'{param}_{symbol_name} '
                lines.append('')
            elif dev_type == 'r' or dev_type == 'R':
                for param in self.params_r:
                    if subckt == '':
                        raise ValueError('In this PDK, resistor is instantiated as a subckt! Subckt is missing here.')
                    else:               
                        if dev_name in self.dev_names_r:
                            raise ValueError('It is not straightforward to extract resistance info from this PDK, \
                                             so for resistance just use Rsheet * L / W / M for approximation. Remove the resistors from the ckt_hierarchy.')
                        else:
                            raise ValueError('This device is not defined in this PDK.')
                    lines.append(line)
                    write_file = write_file + f'{param}_{symbol_name} '
                lines.append('')    
            elif dev_type == 'c' or dev_type == 'C':
                for param in self.params_c:
                    if subckt == '':
                        raise ValueError('In this PDK, capacitor is instantiated as a subckt! Subckt is missing here.')
                    else:
                        if dev_name in self.dev_names_c:
                            raise ValueError('It is not straightforward to extract resistance info from this PDK, \
                                             so for resistance just use Csheet * (L * W) * M for approximation. Remove the capacitors from the ckt_hierarchy.')                
                        else:
                            raise ValueError('This device is not defined in this PDK.')
                    lines.append(line)
                    write_file = write_file + f'{param}_{symbol_name} '
                lines.append('')    
            elif dev_type == 'i' or dev_type == 'I':
                for param in self.params_i:
                    if subckt == '':
                        line = f'let {param}_{symbol_name}=@{dev_name}[{param}]'
                    else:
                        line = f'let {param}_{symbol_name}=@i.{subckt}.{dev_name}[{param}]'
                    lines.append(line)
                    write_file = write_file + f'{param}_{symbol_name} '
                lines.append('')    
            elif dev_type == 'v' or dev_type == 'V':
                for param in self.params_v:
                    if subckt == '':
                        line = f'let {param}_{symbol_name}=@{dev_name}[{param}]'
                    else:
                        line = f'let {param}_{symbol_name}=@v.{subckt}.{dev_name}[{param}]'
                    lines.append(line)
                    write_file = write_file + f'{param}_{symbol_name} '
                lines.append('')           
            else:
                None
                
        lines.append(f'write {file_name} ' + write_file)
        
        return lines  
    
            
if __name__ == '__main__':
    ckt_hierarchy = GraphDoubleTailComp().ckt_hierarchy      
    dev_params_script = DeviceParams(ckt_hierarchy).gen_dev_params(file_name='double_tail_comp_tb_op')
    
    with open('simulations/double_tail_comp_tb_dev_params.spice', 'w') as f:
        for line in dev_params_script:
            f.write(f'{line}\n')    

    ckt_hierarchy = GraphStrongArmComp().ckt_hierarchy      
    dev_params_script = DeviceParams(ckt_hierarchy).gen_dev_params(file_name='strong_arm_comp_tb_op')
    
    with open('simulations/strong_arm_comp_tb_dev_params.spice', 'w') as f:
        for line in dev_params_script:
            f.write(f'{line}\n')    
         
            
            
            
            
            
            
            
            
            
            
            
            
            
            