set theScr {

    # Initialize parameters
    init -filename parameters_insar.tcl

    set logCmd dputs

    set imaIdf vel_map
    set type xsm_fftw${useFftw}_nmaxsup${useNMaxSup}_gpu${useGPU}
    dputs " wtmm $wavelet on InSAR velocity map"

    # Load the exported velocity map
    iload velocity_map.xsm ${imaIdf}
    dputs "Loaded velocity map"

    # Save a copy in the base directory
    isave ${imaIdf} ${baseDir}/${imaIdf}

    # Create output directory for WTMM edges
    file mkdir ${baseDir}/${imaIdf}_${type}_max_${wavelet}

    # Main WTMM: compute edges per scale
    # NOTE: we keep mod and arg in memory (no delete) so VTK -color works
    wtmmg ${imaIdf} {
        esave max$scaleIdF ${baseDir}/${imaIdf}_${type}_max_${wavelet}/max$scaleIdF
    }
    dputs "End wtmm."

    # Compute border size
    set b1 [GetBorderSize]
    set b2 [expr { $size - $b1 }]
    dputs "b1 $b1  b2 $b2"

    # Vertical chaining across scales
    dputs " chain..."
    chain m $amin $noct $nvox \
        -filename ${baseDir}/${imaIdf}_${type}_max_${wavelet}/max \
        -boxratio 1 \
        -ecut [list $b1 $b1 $b2 $b2] \
        -nomsg

    # Export 3D skeleton to VTK for ParaView
    set lastSid [format "%.3d" [expr {$noct * $nvox - 1}]]
    dputs "Exporting skeleton from m${lastSid} to VTK..."
    eisave_skel4vtk m${lastSid} ${baseDir}/skeleton_vert.vtk
    eisave_skelchain4vtk m${lastSid} ${baseDir}/skeleton_horiz.vtk 1.0
    dputs "VTK files written."

    # Compute partition functions
    file mkdir ${baseDir}/pf
    if {[file exists ${baseDir}/pf/pf_${type}_${imaIdf}_${wavelet}] == 0} {
        dputs " Computing the pf..."

        set zepf [pf create]
        pf init $zepf $amin $noct $nvox $q_lst $size "Gradient max" {}
        pf compute $zepf m
        pf save $zepf ${baseDir}/pf/pf_${type}_${imaIdf}_${wavelet}
        pf destroy $zepf
        dputs " ok."
    } else {
        dputs " Pf already computed."
    }

    dputs "pf computed!"
    logMsg "End."
}

ist $theScr
