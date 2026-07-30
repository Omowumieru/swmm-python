/*
 *  stats_typemaps.i - SWIG interface description file for swmm structs
 *
 *  Created:    11/16/2020
 *  Updated:
 *
 *  Author:     See AUTHORS
 * 
*/


%define %statsmaps(Type)
%typemap(in, numinputs=0) Type *out_stats (Type *temp) {
    temp = (Type *)calloc(1, sizeof(Type));
    $1 = temp;
}
%typemap(argout) Type *out_stats {
    %append_output(SWIG_NewPointerObj(SWIG_as_voidptr(temp$argnum), $1_descriptor, 0));
}
%enddef

%statsmaps(SM_NodeStats);
%apply SM_NodeStats *out_stats {
    SM_NodeStats *nodeStats
}

%statsmaps(SM_StorageStats);
%apply SM_StorageStats *out_stats {
    SM_StorageStats *storageStats
}


/* PROVIDE CUSTOM CONSTRUCTOR/DECONSTRUCTOR */
%nodefaultctor SM_OutfallStats;

%extend SM_OutfallStats {
    SM_OutfallStats(int num_pollut) {
        SM_OutfallStats *s = (SM_OutfallStats *)calloc(1, sizeof(SM_OutfallStats));
        if (num_pollut > 0)
            s->totalLoad = (double *)calloc(num_pollut, sizeof(double));
        return s;
    }
    ~SM_OutfallStats(SM_OutfallStats *self) {
        if (self != NULL)
            free(self->totalLoad);
        free(self);
    }
    double get_totalLoad(int index) {
        return self->totalLoad[index];
    }
}

%typemap(in, numinputs=0) SM_OutfallStats *out_outfall_stats (SM_OutfallStats *temp) {
    int num_pollut;
    swmm_countObjects(SM_POLLUT, &num_pollut);
    temp = new_SM_OutfallStats(num_pollut);
    $1 = temp;
}
%typemap(argout) SM_OutfallStats *out_outfall_stats {
    %append_output(SWIG_NewPointerObj(SWIG_as_voidptr(temp$argnum), $1_descriptor, 0));
}

%apply SM_OutfallStats *out_outfall_stats {
    SM_OutfallStats *outfallStats
}



%statsmaps(SM_LinkStats);
%apply SM_LinkStats *out_stats {
    SM_LinkStats *linkStats
}


%statsmaps(SM_PumpStats);
%apply SM_PumpStats *out_stats {
    SM_PumpStats *pumpStats
}


%statsmaps(SM_SubcatchStats);
%apply SM_SubcatchStats *out_stats {
    SM_SubcatchStats *subcatchStats
}

%statsmaps(SM_GWaterState);
%apply SM_GWaterState *out_stats {
    SM_GWaterState *gWaterState
}

%statsmaps(SM_RoutingTotals);
%apply SM_RoutingTotals *out_stats {
    SM_RoutingTotals *routingTotals
}


%statsmaps(SM_RunoffTotals);
%apply SM_RunoffTotals *out_stats {
    SM_RunoffTotals *runoffTotals
}

/* Helper for the SM_GWaterState input typemap below. Reads one optional
   member out of the Python dict. Returns 1 if the key was present, 0 if it
   was absent, -1 on a bad value. *out is left alone unless a real number was
   supplied, so the solver's "leave unchanged" sentinel survives both an
   absent key and an explicit None. */
%{
#define SM_GWATERSTATE_UNCHANGED -999

static int gwaterstate_get_member(PyObject *dict, const char *key, double *out)
{
    PyObject *value = PyDict_GetItemString(dict, key);

    if (value == NULL)
        return 0;
    if (value == Py_None)
        return 1;

    *out = PyFloat_AsDouble(value);
    if (PyErr_Occurred()) {
        PyErr_Clear();
        PyErr_Format(PyExc_TypeError,
            "swmm.toolkit.solver.gw_set_state: value for '%s' must be a number.",
            key);
        return -1;
    }
    return 1;
}
%}

/* Input typemap so a Python dict can be passed into the solver as an
   SM_GWaterState. Keys are optional: anything left out keeps the -999
   sentinel and is not modified by swmm_setGWaterState().

   The parameter name gWaterState_in (rather than gWaterState) is what keeps
   this typemap distinct from the %statsmaps output typemap applied to
   swmm_getGWaterState above - SWIG matches typemaps on type *and* name. */
%typemap(in) SM_GWaterState *gWaterState_in (SM_GWaterState temp) {
    int found = 0, result;

    if (!PyDict_Check($input)) {
        PyErr_SetString(PyExc_TypeError,
            "swmm.toolkit.solver.gw_set_state: expected a dict with any of the "
            "keys 'theta', 'gwt_elev', 'new_flow', 'max_infil_volume'.");
        SWIG_fail;
    }

    temp.theta       = SM_GWATERSTATE_UNCHANGED;
    temp.gwtElev     = SM_GWATERSTATE_UNCHANGED;
    temp.newFlow     = SM_GWATERSTATE_UNCHANGED;
    temp.maxInfilVol = SM_GWATERSTATE_UNCHANGED;

    if ((result = gwaterstate_get_member($input, "theta", &temp.theta)) < 0)
        SWIG_fail;
    found += result;
    if ((result = gwaterstate_get_member($input, "gwt_elev", &temp.gwtElev)) < 0)
        SWIG_fail;
    found += result;
    if ((result = gwaterstate_get_member($input, "new_flow", &temp.newFlow)) < 0)
        SWIG_fail;
    found += result;
    if ((result = gwaterstate_get_member($input, "max_infil_volume", &temp.maxInfilVol)) < 0)
        SWIG_fail;
    found += result;

    /* Every member defaults to "unchanged", so an unrecognised key would
       otherwise be silently ignored. Comparing counts avoids reading the key
       strings, which the limited API cannot do before Python 3.10. */
    if (found != (int)PyDict_Size($input)) {
        PyErr_SetString(PyExc_KeyError,
            "swmm.toolkit.solver.gw_set_state: unrecognised key. Valid keys are "
            "'theta', 'gwt_elev', 'new_flow', 'max_infil_volume'.");
        SWIG_fail;
    }

    $1 = &temp;
}

/* WRAP PUBLIC STRUCTURES AND GENERATE GETTERS */
%immutable;
%include "toolkit_structs.h"
%noimmutable;
