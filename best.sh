
##########################################################
#  _    __          __             ____  __              #
# | |  / /__  _____/ /_____  _____/ __ )/ /___  _  __    #
# | | / / _ \/ ___/ __/ __ \/ ___/ __  / / __ \| |/_/    #
# | |/ /  __/ /__/ /_/ /_/ / /  / /_/ / / /_/ />  <      #
# |___/\___/\___/\__/\____/_/  /_____/_/\____/_/|_|      #
#                                                        #
# https://github.com/Microchip-Vectorblox/VectorBlox-SDK #
# v3.0                                                   #
#                                                        #
##########################################################

set -e
echo "Checking and activating VBX Python Environment..."
if [ -z $VBX_SDK ]; then
    echo "\$VBX_SDK not set. Please run 'source setup_vars.sh' from the SDK's root folder" && exit 1
fi
source $VBX_SDK/vbx_env/bin/activate

echo "Checking for yolov8n-relu files..."

# model details @ https://github.com/ultralytics/ultralytics/
#[ -f coco.names ] || wget -q https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names
if [ ! -f best.pt ]; then
    wget -q --no-check-certificate https://github.com/ADYASHREECR20/tea/blob/main/best.pt

    wget -q --no-check-certificate https://github.com/ADYASHREECR20/tea/blob/main/test.jpg

    # wget -q --no-check-certificate https://github.com/Microchip-Vectorblox/assets/releases/download/assets/yolov8n-relu.tflite
fi
if [ ! -f best.tflite ]; then
    # ignore ultralytics yolo command error, we only care about the Tflite which is generated
    yolo export model=best.pt format=tflite int8 || true
    cp best_saved_model/best_full_integer_quant.tflite best.tflite
fi


if [ -f best.tflite ]; then
   tflite_preprocess best.tflite  --scale 255.
fi

if [ -f best.pre.tflite ]; then
    echo "Generating VNNX for V1000 ncomp configuration..."
    vnnx_compile -s V1000 -c ncomp -t best.pre.tflite  -o best_V1000_ncomp.vnnx
fi

if [ -f best_V1000_ncomp.vnnx ]; then
    echo "Running Simulation..."
    python $VBX_SDK/example/python/yoloInfer.py best_V1000_ncomp.vnnx $VBX_SDK/tutorials/test_images/test.jpg -v 8 -l coco.names 
    echo "C Simulation Command:"
    echo '$VBX_SDK/example/sim-c/sim-run-model best_V1000_ncomp.vnnx $VBX_SDK/tutorials/test_images/test.jpg ULTRALYTICS_FULL'
fi

deactivate
