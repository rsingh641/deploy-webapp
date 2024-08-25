#! /bin/bash

set -e

source src/lib/initialize
source src/lib/ui/ui_manage

swap_slots $WEBAPP_SLOT_GREEN $WEBAPP_SLOT_BLUE

