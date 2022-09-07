namespace SKU
{

struct InputDeviceWii : InputDevice {
    void UpdateInput();
    void ProcessInput(int32 controllerID);
    void CloseDevice();

    uint32 buttonMasks;
    uint32 prevButtonMasks;
    uint8 stateUp;
    uint8 stateDown;
    uint8 stateLeft;
    uint8 stateRight;
    uint8 stateA;
    uint8 stateB;
    uint8 stateC;
    uint8 stateX;
    uint8 stateY;
    uint8 stateZ;
    uint8 stateStart;
    uint8 stateSelect;
};

void InitWiiInputAPI();

InputDeviceWii *InitWiiInputDevice(uint32 id);

} // namespace SKU