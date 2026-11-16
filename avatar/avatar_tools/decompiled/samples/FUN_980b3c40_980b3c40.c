
undefined8 FUN_980b3c40(void)

{
  undefined4 *puVar1;
  
  puVar1 = (undefined4 *)FUN_980618cc();
  if ((DAT_981919b0 & 1) == 0) {
    DAT_981919b0 = DAT_981919b0 | 1;
    DAT_98191900 = L"CameraElement";
    DAT_981918f4 = 0;
    DAT_981918f8 = 4;
    DAT_981918fc = 0;
    DAT_98191904 = 5;
    DAT_98191908 = FUN_980b0e08();
    DAT_9819190c = 0;
    DAT_98191910 = 0;
    DAT_98191914 = 0;
    DAT_98191918 = 0;
    DAT_9819191c = 0;
    DAT_98191930 = L"AmbientLight";
    DAT_98191924 = 1;
    DAT_98191920 = 0;
    DAT_9819192c = 0;
    DAT_98191928 = 8;
    DAT_98191934 = 6;
    DAT_98191938 = FUN_980b0718();
    DAT_9819193c = 0;
    DAT_98191940 = 0;
    DAT_98191944 = 0;
    DAT_98191948 = 0;
    DAT_9819194c = 0;
    DAT_98191960 = L"SunLightDirection";
    DAT_98191954 = 2;
    DAT_98191950 = 0;
    DAT_9819195c = 0;
    DAT_98191958 = 0xc;
    DAT_98191964 = 7;
    DAT_98191968 = FUN_980b0680();
    DAT_9819196c = 0;
    DAT_98191970 = 0;
    DAT_98191974 = 0;
    DAT_98191978 = 0;
    DAT_98191980 = 0;
    DAT_98191990 = L"SunLightColor";
    DAT_98191984 = 3;
    DAT_98191988 = 0x18;
    DAT_9819198c = 0;
    DAT_98191994 = 6;
    DAT_98191998 = FUN_980b0788();
    DAT_9819199c = 0;
    DAT_981919a0 = 0;
    DAT_981919a4 = 0;
    DAT_981919a8 = 0;
    DAT_981919ac = 0;
  }
  *puVar1 = 4;
  return 0xffffffff981918f0;
}

