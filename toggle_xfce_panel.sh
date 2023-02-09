#!/bin/bash

PANELNUM=2
xfconf-query -c xfce4-panel -p "/panels/panel-$PANELNUM/autohide-behavior" -s $(( $( xfconf-query -c xfce4-panel -p "/panels/panel-$PANELNUM/autohide-behavior" ) ^ 2 ))