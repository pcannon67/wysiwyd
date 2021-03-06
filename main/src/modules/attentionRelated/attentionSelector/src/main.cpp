// -*- mode:C++; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

/* 
* Copyright (C) 2014 WYSIWYD Consortium, European Commission FP7 Project ICT-612139
* Authors: Stéphane Lallée, moved from EFAA by Maxime Petit
* email:   stephane.lallee@gmail.com
* website: http://wysiwyd.upf.edu/ 
* Permission is granted to copy, distribute, and/or modify this program
* under the terms of the GNU General Public License, version 2 or any
* later version published by the Free Software Foundation.
*
* A copy of the license can be found at
* $WYSIWYD_ROOT/license/gpl.txt
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details
*/

/**
* @file main.cpp
* @brief main code.
*/

#include "attentionSelector.h"
#include <yarp/os/all.h>
#include <time.h>

using namespace yarp::os;
using namespace yarp::sig;


int main(int argc, char * argv[]) {
    srand((int)time(NULL));
    /* initialize yarp network */
    Network yarp;

    /* prepare and configure the resource finder */
    ResourceFinder rf;
    rf.setVerbose(true);
    rf.setDefaultConfigFile("attentionSelector.ini"); //overridden by --from parameter
    rf.setDefaultContext("attentionSelector");   //overridden by --context parameter 
    rf.configure(argc, argv);

    /* create your module */
    attentionSelectorModule module; 

    /* run the module: runModule() calls configure first and, if successful, it then runs */
    module.runModule(rf);

    return 0;
}

