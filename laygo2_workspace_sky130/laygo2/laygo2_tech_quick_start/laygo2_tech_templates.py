# -*- coding: utf-8 -*-
########################################################################################################################
#
# Copyright (c) 2020, Nifty Chips Laboratory, Hanyang University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#   disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#    following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
########################################################################################################################

"""Template library for the advanced example technology. (advtech)"""

import numpy as np

import laygo2.object.template
import laygo2.object.physical
import laygo2.object.database

# Should be `import laygo2_tech as tech` for actual use.
# import laygo2_tech as tech
import laygo2_tech_quick_start as tech

# tech_params = tech.tech_params
# templates = tech_params["templates"]
# grids = tech_params["grids"]

# Template functions for primitive devices
def _mos_update_params(params):
    """Make a complete parameter table for mos"""
    us = np.array([30, 100])  # unit transistor size
    params["nf"]              = params.get("nf",              1)     # number of fingers
    params["nfdmyl"]          = params.get("nfdmyl",          0)     # number of left-dummy fingers
    params["nfdmyr"]          = params.get("nfdmyr",          0)     # number of right-dummy fingers
    params["trackswap"]       = params.get("trackswap",       False) # s/d track swap
    params["tie"]             = params.get("tie",             None)  # tie to power rail
    params["bndl"]            = params.get("bndl",            True)  # create local left boundary
    params["bndr"]            = params.get("bndr",            True)  # create local right boundary
    params["gbndl"]           = params.get("gbndl",           True)  # create global left boundary
    params["gbndr"]           = params.get("gbndr",           True)  # create global right boundary
    params["unit_size_core"]  = params.get("unit_size_core",  us)    # core unit size
    params["unit_size_dmy"]   = params.get("unit_size_dmy",   us)    # dummy unit size
    params["unit_size_bndl"]  = params.get("unit_size_bndl",  us)    # left local boundary size
    params["unit_size_bndr"]  = params.get("unit_size_bndr",  us)    # right local boundary size
    params["unit_size_gbndl"] = params.get("unit_size_gbndl", us)    # left global boundary size
    params["unit_size_gbndr"] = params.get("unit_size_gbndr", us)    # right global boundary size
    return params


def mos_bbox_func(params):
    """Computes x and y coordinate values from params."""
    params = _mos_update_params(params)
    unit_size = params["unit_size_core"]
    xy0 = [0, 0]
    xy1 = [unit_size[0] * params["nf"], unit_size[1]]
    xy = np.array([xy0, xy1])
    # Increment bbox based on boundary / dummy parameters.
    if params["gbndl"]:
        xy[1, 0] += params["unit_size_gbndl"][0]
    if params["bndl"]:
        xy[1, 0] += params["unit_size_bndl"][0]
    if params["nfdmyl"] > 0:
        xy[1, 0] += params["unit_size_dmy"][0] * round(params["nfdmyl"])
    if params["nfdmyr"] > 0:
        xy[1, 0] += params["unit_size_dmy"][0] * round(params["nfdmyr"])
    if params["bndr"]:
        xy[1, 0] += params["unit_size_bndr"][0]
    if params["gbndr"]:
        xy[1, 0] += params["unit_size_gbndr"][0]
    return xy


def mos_pins_func(devtype, params):
    """Generate a pin dictionary from params."""
    # Compute parameters
    params = _mos_update_params(params)
    nf = params["nf"] 
    nfdl = params["nfdmyl"]
    nfdr = params["nfdmyr"]
    blx = 30 if params["bndl"] == True else 0
    brx = 30 if params["bndr"] == True else 0
    gblx = 30 if params["gbndl"] == True else 0
    gbrx = 30 if params["gbndr"] == True else 0
    us = np.array([30, 100])  # unit transistor size

    # Create a pin dictionary
    pins = dict()
    # metal2 - gate
    pxy = np.array([[gblx + blx + us[0] * nfdl + 12, 75], [gblx + blx + us[0] * (nfdl + nf) - 12, us[1] - 15]])
    pins["G"] = laygo2.object.Pin(name="G", xy=pxy, layer=["metal2", "drawing"], netname="G")
    # metal2 - sourcedrain
    srx = -1 * (nf % 2) * us[0]
    if params["trackswap"] == False:
        sy = 25
        dy = 45
    else:
        sy = 45
        dy = 25
    sdx = gblx + blx + nfdl * us[0]
    pxy = np.array([[sdx - 7, sy], [sdx + us[0] * nf + srx + 7, sy + 10]])
    pins["S"] = laygo2.object.Pin(name="S", xy=pxy, layer=["metal2", "drawing"], netname="S")
    drx = -1 * ((nf + 1) % 2) * us[0]
    pxy = np.array([[sdx + us[0] - 7, dy], [sdx + us[0] * nf + drx + 7, dy + 10]])
    pins["D"] = laygo2.object.Pin(name="D", xy=pxy, layer=["metal2", "drawing"], netname="D")
    # metal2 - rail
    pxy = np.array([[0, -5], [gblx + blx + us[0] * (nfdl + nf + nfdr) + brx + gbrx, 5]])
    pins["RAIL"] = laygo2.object.Pin(name="RAIL", xy=pxy, layer=["metal2", "drawing"], netname="RAIL")
    return pins


def pmos_pins_func(params):
    return mos_pins_func(devtype="pmos", params=params)


def nmos_pins_func(params):
    return mos_pins_func(devtype="nmos", params=params)


def mos_generate_func(devtype, name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    """Generates an instance from the input parameters."""
    # Compute parameters
    params = _mos_update_params(params)
    nf = params["nf"] if "nf" in params.keys() else 1
    nfdl = params["nfdmyl"]
    nfdr = params["nfdmyr"]
    blx = 30 if params["bndl"] == True else 0
    brx = 30 if params["bndr"] == True else 0
    gblx = 30 if params["gbndl"] == True else 0
    gbrx = 30 if params["gbndr"] == True else 0
    us = np.array([30, 100])  # unit transistor size

    # Create the base mosfet structure.
    nelements = dict()
    # prboundary
    rxy = np.array([[0, 0], [gblx + blx + us[0] * (nfdl + nf + nfdr) + brx + gbrx, us[1]]])
    nelements["PRBND0"] = laygo2.object.Rect(xy=rxy, layer=["prBoundary", "drawing"], name="PRBND0")
    # well
    if devtype == "pmos":
        rxy = np.array([[-20, 0], [gblx + blx + us[0] * (nfdl + nf + nfdr) + brx + gbrx + 20, us[1]]])
        nelements["NW0"] = laygo2.object.Rect(xy=rxy, layer=["nwell", "drawing"], name="NW0")
    # implant
    rxy = np.array([[0, 5], [gblx + blx + us[0] * (nfdl + nf + nfdr) + brx + gbrx, us[1] - 5]])
    if devtype == "nmos":
        nelements["NIMPL0"] = laygo2.object.Rect(xy=rxy, layer=["nimplant", "drawing"], name="NIMPL0")
    else:
        nelements["PIMPL0"] = laygo2.object.Rect(xy=rxy, layer=["pimplant", "drawing"], name="PIMPL0")
    # diffusion
    rxy = np.array([[gblx + blx - 5, 15], [gblx + blx + us[0] * (nfdl + nf + nfdr) + 5, us[1] - 35]])
    nelements["DIFF0"] = laygo2.object.Rect(xy=rxy, layer=["diffusion", "drawing"], name="DIFF0")
    # poly
    for i in range(nf + nfdl + nfdr):
        rxy = np.array([[gblx + blx + us[0] * i + 12, 10], [gblx + blx + us[0] * (i + 1) - 12, us[1] - 10]])
        nelements["POLY" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["poly", "drawing"], name="POLY" + str(i))
    # metal1 - gate
    rxy = np.array([[gblx + blx + us[0] * nfdl + 12, 75], [gblx + blx + us[0] * (nfdl + nf) - 12, us[1] - 15]])
    nelements["M1G0"] = laygo2.object.Rect(xy=rxy, layer=["metal1", "drawing"], name="M1G0")
    # metal1 - sourcedrain
    for i in range(nf + nfdl + nfdr + 1):
        rxy = np.array([[gblx + blx + us[0] * i - 7, 13], [gblx + blx + us[0] * i + 7, us[1] - 33]])
        nelements["M1SD" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["metal1", "drawing"], name="M1SD" + str(i))
    # via1 - gate
    gx = gblx + blx + nfdl * us[0]
    for i in range(nf):
        rxy = np.array([[gx + us[0] * i - 5 + 15, 75], [gx + us[0] * i + 5 + 15, us[1] - 15]])
        nelements["VG0" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="VG0" + str(i))
    # via1 - sourcedrain
    if params["trackswap"] == False:
        sy = 25
        dy = 45
    else:
        sy = 45
        dy = 25
    sdx = gblx + blx + nfdl * us[0]
    for i in range(nf + 1):
        if i % 2 == 0:
            rxy = np.array([[sdx + us[0] * i - 5, sy], [sdx + us[0] * i + 5, sy + 10]])
            nelements["VS0" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="VS0" + str(i))
        else:
            rxy = np.array([[sdx + us[0] * i - 5, dy], [sdx + us[0] * i + 5, dy + 10]])
            nelements["VD0" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="VD0" + str(i))
    # metal1/via1 - tie
    sdx = gblx + blx + nfdl * us[0]
    for i in range(nf + 1):
        tie = False
        if (i % 2 == 0) and (params["tie"] is not None):
            if params["tie"] == "S":
                tie = True
        if (i % 2 == 1) and (params["tie"] is not None):
            if params["tie"] == "D":
                tie = True
        if tie:
            rxy = np.array([[sdx + us[0] * i - 7, -5], [sdx + us[0] * i + 7, 23]])
            nelements["M1TIE" + str(i)] = laygo2.object.Rect(
                xy=rxy, layer=["metal1", "drawing"], name="M1TIE" + str(i)
            )
            rxy = np.array([[sdx + us[0] * i - 5, -5], [sdx + us[0] * i + 5, 5]])
            nelements["V1TIE" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="V1TIE" + str(i))
    # metal1 - dummy (gate)
    if nfdl > 0:
        rxy = np.array([[gblx + blx + 12, 75], [gblx + blx + us[0] * nfdl - 12, us[1] - 15]])
        nelements["M1DMYGL"] = laygo2.object.Rect(xy=rxy, layer=["metal1", "drawing"], name="M1DMYGL")
        #gx = gblx + blx
        #for i in range(nfdl):
        #    rxy = np.array([[gx + us[0] * i - 5 + 15, 75], [gx + us[0] * i + 5 + 15, us[1] - 15]])
        #    nelements["VDMYGL" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="VDMYGL" + str(i))
    if nfdr > 0:
        rxy = np.array([[gblx + blx + us[0] * (nfdl + nf) + 12, 75], [gblx + blx + us[0] * (nfdl + nf + nfdr) - 12, us[1] - 15]])
        nelements["M1DMYGR"] = laygo2.object.Rect(xy=rxy, layer=["metal1", "drawing"], name="M1DMYGR")
        #gx = gblx + blx + (nfdl + nf) * us[0]
        #for i in range(nfdr):
        #    rxy = np.array([[gx + us[0] * i - 5 + 15, 75], [gx + us[0] * i + 5 + 15, us[1] - 15]])
        #    nelements["VDMYGR" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="VDMYGR" + str(i))
    # metal1/via1 - dummy (source/drain)
    sdx = gblx + blx
    for i in range(nfdl + 1 - 1):
        if i == 0:
            rxy = np.array([[sdx + us[0] * i - 7, -5], [sdx + us[0] * i + 7, 23]])
        else:
            rxy = np.array([[sdx + us[0] * i - 7, -5], [sdx + us[0] * i + 7, us[1] - 15]])
        nelements["M1DML" + str(i)] = laygo2.object.Rect(
            xy=rxy, layer=["metal1", "drawing"], name="M1DML" + str(i)
        )
        rxy = np.array([[sdx + us[0] * i - 5, -5], [sdx + us[0] * i + 5, 5]])
        nelements["V1DML" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="V1DML" + str(i))
    sdx = gblx + blx + (nfdl + nf) * us[0]
    for i in range(1, nfdr + 1):
        if i == nfdr:
            rxy = np.array([[sdx + us[0] * i - 7, -5], [sdx + us[0] * i + 7, 23]])
        else:
            rxy = np.array([[sdx + us[0] * i - 7, -5], [sdx + us[0] * i + 7, us[1] - 15]])
        nelements["M1DMR" + str(i)] = laygo2.object.Rect(
            xy=rxy, layer=["metal1", "drawing"], name="M1DMR" + str(i)
        )
        rxy = np.array([[sdx + us[0] * i - 5, -5], [sdx + us[0] * i + 5, 5]])
        nelements["V1DMR" + str(i)] = laygo2.object.Rect(xy=rxy, layer=["via1", "drawing"], name="V1DMR" + str(i))
    
    # metal2 - gate
    sdx = gblx + blx + nfdl * us[0]
    rxy = np.array([[gblx + blx + us[0] * nfdl + 12, 75], [gblx + blx + us[0] * (nfdl + nf) - 12, us[1] - 15]])
    nelements["M2G0"] = laygo2.object.Rect(xy=rxy, layer=["metal2", "drawing"], name="M2G0")
    # metal2 - sourcedrain
    srx = -1 * (nf % 2) * us[0]
    rxy = np.array([[sdx - 7, sy], [sdx + us[0] * nf + srx + 7, sy + 10]])
    nelements["M2S0"] = laygo2.object.Rect(xy=rxy, layer=["metal2", "drawing"], name="M2S0")
    drx = -1 * ((nf + 1) % 2) * us[0]
    rxy = np.array([[sdx + us[0] - 7, dy], [sdx + us[0] * nf + drx + 7, dy + 10]])
    nelements["M2D0"] = laygo2.object.Rect(xy=rxy, layer=["metal2", "drawing"], name="M2D0")
    # metal2 - rail
    rxy = np.array([[0, -5], [gblx + blx + us[0] * (nfdl + nf + nfdr) + brx + gbrx, 5]])
    nelements["M2RAIL0"] = laygo2.object.Rect(xy=rxy, layer=["metal2", "drawing"], name="M2RAIL0")

    # Create pins
    pins = mos_pins_func(devtype=devtype, params=params)
    nelements.update(pins)  # Add physical pin structures to the virtual object.

    # inst_unit_size = unit_size * np.array([nf, 1])
    # Unit size
    inst_xy = mos_bbox_func(params=params)
    inst_unit_size = [inst_xy[1, 0] - inst_xy[0, 0], inst_xy[1, 1] - inst_xy[0, 1]]

    # Generate and return the final instance
    inst = laygo2.object.VirtualInstance(
        name=name,
        xy=np.array([0, 0]),
        libname="mylib",
        cellname="myvcell_" + devtype,
        native_elements=nelements,
        shape=shape,
        pitch=pitch,
        transform=transform,
        unit_size=inst_unit_size,
        pins=pins,
    )
    return inst


def pmos_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return mos_generate_func(devtype="pmos", name=name, shape=shape, pitch=pitch, transform=transform, params=params)


def nmos_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return mos_generate_func(devtype="nmos", name=name, shape=shape, pitch=pitch, transform=transform, params=params)


# Spacers
def space_bbox_func(params):
    """Computes x and y coordinate values from params."""
    us = np.array([30, 100])  # unit space
    xy0 = [0, 0]
    xy1 = [us[0] * params["nf"], us[1]]
    xy = np.array([xy0, xy1])
    return xy


def space_pins_func(params):
    return None


def space_generate_func(devtype="pmos", name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    # Compute parameters
    nf = params["nf"] if "nf" in params.keys() else 1
    us = np.array([30, 100])  # unit space

    # Create the base mosfet structure.
    nelements = dict()
    # prboundary
    rxy = np.array([[0, 0], [us[0] * nf, us[1]]])
    nelements["PRBND0"] = laygo2.object.Rect(xy=rxy, layer=["prBoundary", "drawing"], name="PRBND0")
    # well
    rxy = np.array([[-20, 0], [us[0] * nf + 20, us[1]]])
    nelements["NW0"] = laygo2.object.Rect(xy=rxy, layer=["nwell", "drawing"], name="NW0")
    # implant
    rxy = np.array([[0, 5], [us[0] * nf, us[1] - 5]])
    if devtype == "nmos":
        nelements["NIMPL0"] = laygo2.object.Rect(xy=rxy, layer=["nimplant", "drawing"], name="NIMPL0")
    else:
        nelements["PIMPL0"] = laygo2.object.Rect(xy=rxy, layer=["pimplant", "drawing"], name="PIMPL0")
    # metal2 - rail
    rxy = np.array([[0, -5], [us[0] * nf, 5]])
    nelements["M2RAIL0"] = laygo2.object.Rect(xy=rxy, layer=["metal2", "drawing"], name="M2RAIL0")

    # Unit size
    inst_xy = space_bbox_func(params=params)
    inst_unit_size = [inst_xy[1, 0] - inst_xy[0, 0], inst_xy[1, 1] - inst_xy[0, 1]]

    # Generate and return the final instance
    inst = laygo2.object.VirtualInstance(
        name=name,
        xy=np.array([0, 0]),
        libname="mylib",
        cellname="myvcell_space_" + devtype,
        native_elements=nelements,
        shape=shape,
        pitch=pitch,
        transform=transform,
        unit_size=inst_unit_size,
        pins=None,
    )
    return inst


def pspace_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return space_generate_func(devtype="pmos", name=name, shape=shape, pitch=pitch, transform=transform, params=params)


def nspace_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return space_generate_func(devtype="nmos", name=name, shape=shape, pitch=pitch, transform=transform, params=params)


# Vias
def via_generate_func(devtype, name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    """Generates an instance from the input parameters."""
    # Create the via structure.
    nelements = dict()
    if devtype.startswith("via_r12"):
        layer = ["via1", "drawing"]
        xy = [[-5, -5], [5, 5]]
    if devtype.startswith("via_r23"):
        layer = ["via2", "drawing"]
        xy = [[-5, -5], [5, 5]]
    if devtype.startswith("via_r34"):
        layer = ["via3", "drawing"]
        xy = [[-5, -5], [5, 5]]
    nelements["VIA0"] = laygo2.object.Rect(xy=xy, layer=layer, name="VIA0")

    # Generate and return the final instance
    inst = laygo2.object.VirtualInstance(
        name=name,
        xy=np.array([0, 0]),
        libname="mylib",
        cellname="myvcell_devtype",
        native_elements=nelements,
        shape=shape,
        pitch=pitch,
        transform=transform,
        unit_size=np.array([0, 0]),
        pins=None,
    )
    return inst


def via_r12_default_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return via_generate_func(
        devtype="via_r12_default", name=name, shape=shape, pitch=pitch, transform=transform, params=params
    )


def via_r23_default_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return via_generate_func(
        devtype="via_r23_default", name=name, shape=shape, pitch=pitch, transform=transform, params=params
    )


def via_r34_default_generate_func(name=None, shape=None, pitch=np.array([0, 0]), transform="R0", params=None):
    return via_generate_func(
        devtype="via_r34_default", name=name, shape=shape, pitch=pitch, transform=transform, params=params
    )


# Template library
def load_templates():
    """Load template to a template library object"""
    tlib = laygo2.object.database.TemplateLibrary(name="advtech_templates")
    # Transistors
    # Transistor layouts are created in laygo and stored as a virtual instance.
    tnmos = laygo2.object.template.UserDefinedTemplate(
        name="nmos", bbox_func=mos_bbox_func, pins_func=nmos_pins_func, generate_func=nmos_generate_func
    )
    tpmos = laygo2.object.template.UserDefinedTemplate(
        name="pmos", bbox_func=mos_bbox_func, pins_func=pmos_pins_func, generate_func=pmos_generate_func
    )
    tlib.append([tpmos, tnmos])
    # Spacers
    tnspace = laygo2.object.template.UserDefinedTemplate(
        name="nspace", bbox_func=space_bbox_func, pins_func=space_pins_func, generate_func=nspace_generate_func
    )
    tpspace = laygo2.object.template.UserDefinedTemplate(
        name="pspace", bbox_func=space_bbox_func, pins_func=space_pins_func, generate_func=pspace_generate_func
    )
    tlib.append([tpspace, tnspace])
    # Vias
    # Via layouts are created in laygo and stored as a virtual instance.
    tvia_r12_default = laygo2.object.template.UserDefinedTemplate(
        name="via_r12_default",
        bbox_func=lambda params: np.array([0, 0]),
        pins_func=lambda params: None,
        generate_func=via_r12_default_generate_func,
    )
    tlib.append([tvia_r12_default])
    tvia_r23_default = laygo2.object.template.UserDefinedTemplate(
        name="via_r23_default",
        bbox_func=lambda params: np.array([0, 0]),
        pins_func=lambda params: None,
        generate_func=via_r23_default_generate_func,
    )
    tlib.append([tvia_r23_default])
    tvia_r34_default = laygo2.object.template.UserDefinedTemplate(
        name="via_r34_default",
        bbox_func=lambda params: np.array([0, 0]),
        pins_func=lambda params: None,
        generate_func=via_r34_default_generate_func,
    )
    tlib.append([tvia_r34_default])
    return tlib


# Tests
if __name__ == "__main__":
    # Create templates.
    print("Create templates")
    templates = load_templates()
    print(templates["nmos"])
    print(templates["pmos"])
