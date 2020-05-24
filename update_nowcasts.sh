#!/bin/bash

## Update shared delay
Rscript update_delay.R

## Run regions in parallel
Rscript afghanistan/update_nowcasts.R & 
Rscript colombia/update_nowcasts.R &
Rscript russia/update_nowcasts.R &
wait