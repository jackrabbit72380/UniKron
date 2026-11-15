
undefined4 __fastcall FUN_0001ce9a(undefined4 *param_1)

{
  int *in_EAX;
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  char cVar5;
  char *pcVar6;
  
  pcVar6 = (char *)param_1[0x2b];
  if (pcVar6 < (char *)param_1[0x2c]) {
    cVar5 = *pcVar6;
    param_1[0x2b] = pcVar6 + 1;
  }
  else if (param_1[8] == 0) {
    cVar5 = '\0';
  }
  else {
    FUN_00015ad1();
    cVar5 = *(char *)param_1[0x2b];
    param_1[0x2b] = (char *)param_1[0x2b] + 1;
  }
  if (cVar5 == 'B') {
    pcVar6 = (char *)param_1[0x2b];
    if (pcVar6 < (char *)param_1[0x2c]) {
LAB_0001cf03:
      cVar5 = *pcVar6;
      param_1[0x2b] = pcVar6 + 1;
    }
    else {
      if (param_1[8] != 0) {
        FUN_00015ad1();
        pcVar6 = (char *)param_1[0x2b];
        goto LAB_0001cf03;
      }
      cVar5 = '\0';
    }
    if (cVar5 == 'M') {
      FUN_00015cd0(param_1);
      FUN_00015c66();
      FUN_00015c66();
      iVar1 = FUN_00015cd0(param_1);
      in_EAX[1] = iVar1;
      iVar1 = FUN_00015cd0(param_1);
      in_EAX[2] = iVar1;
      in_EAX[6] = 0;
      in_EAX[5] = 0;
      in_EAX[4] = 0;
      in_EAX[3] = 0;
      in_EAX[8] = 0xe;
      if (-1 < in_EAX[1]) {
        if (iVar1 == 0xc) {
          uVar2 = FUN_00015c66();
          *param_1 = uVar2;
          uVar2 = FUN_00015c66();
        }
        else {
          if ((((iVar1 != 0x28) && (iVar1 != 0x38)) && (iVar1 != 0x6c)) && (iVar1 != 0x7c)) {
            pcVar6 = "unknown BMP";
            goto LAB_0001d133;
          }
          uVar2 = FUN_00015cd0(param_1);
          *param_1 = uVar2;
          uVar2 = FUN_00015cd0(param_1);
        }
        param_1[1] = uVar2;
        iVar3 = FUN_00015c66();
        if (iVar3 == 1) {
          iVar3 = FUN_00015c66();
          *in_EAX = iVar3;
          if (iVar1 == 0xc) {
            return 1;
          }
          iVar3 = FUN_00015cd0(param_1);
          if ((iVar3 == 1) || (iVar3 == 2)) {
            pcVar6 = "BMP RLE";
            goto LAB_0001d133;
          }
          if (3 < iVar3) {
            pcVar6 = "BMP JPEG/PNG";
            goto LAB_0001d133;
          }
          if (((iVar3 != 3) || (*in_EAX == 0x10)) || (*in_EAX == 0x20)) {
            FUN_00015cd0(param_1);
            FUN_00015cd0(param_1);
            FUN_00015cd0(param_1);
            FUN_00015cd0(param_1);
            FUN_00015cd0(param_1);
            if (iVar1 != 0x28) {
              if (iVar1 != 0x38) {
                if ((iVar1 == 0x6c) || (iVar1 == 0x7c)) {
                  iVar4 = FUN_00015cd0(param_1);
                  in_EAX[3] = iVar4;
                  iVar4 = FUN_00015cd0(param_1);
                  in_EAX[4] = iVar4;
                  iVar4 = FUN_00015cd0(param_1);
                  in_EAX[5] = iVar4;
                  iVar4 = FUN_00015cd0(param_1);
                  in_EAX[6] = iVar4;
                  if (iVar3 != 3) {
                    FUN_0001ce34(iVar3);
                  }
                  FUN_00015cd0(param_1);
                  iVar3 = 0xc;
                  do {
                    FUN_00015cd0(param_1);
                    iVar3 = iVar3 + -1;
                  } while (iVar3 != 0);
                  if (iVar1 == 0x7c) {
                    FUN_00015cd0(param_1);
                    FUN_00015cd0(param_1);
                    FUN_00015cd0(param_1);
                    FUN_00015cd0(param_1);
                    return 1;
                  }
                  return 1;
                }
                goto LAB_0001d120;
              }
              FUN_00015cd0(param_1);
              FUN_00015cd0(param_1);
              FUN_00015cd0(param_1);
              FUN_00015cd0(param_1);
            }
            if ((*in_EAX != 0x10) && (*in_EAX != 0x20)) {
              return 1;
            }
            if (iVar3 == 0) {
              FUN_0001ce34(0);
              return 1;
            }
            if (iVar3 == 3) {
              iVar1 = FUN_00015cd0(param_1);
              in_EAX[3] = iVar1;
              iVar1 = FUN_00015cd0(param_1);
              in_EAX[4] = iVar1;
              iVar1 = FUN_00015cd0(param_1);
              in_EAX[8] = in_EAX[8] + 0xc;
              in_EAX[5] = iVar1;
              if (in_EAX[3] != in_EAX[4]) {
                return 1;
              }
              if (in_EAX[4] != iVar1) {
                return 1;
              }
            }
          }
        }
      }
LAB_0001d120:
      pcVar6 = "bad BMP";
      goto LAB_0001d133;
    }
  }
  pcVar6 = "not BMP";
LAB_0001d133:
  FUN_00015771(pcVar6);
  return 0;
}

