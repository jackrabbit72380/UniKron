
/* WARNING: Control flow encountered bad instruction data */

undefined8
FUN_980b9b20(undefined8 param_1,int *param_2,undefined8 param_3,int param_4,int param_5,int param_6,
            undefined8 param_7,undefined4 param_8)

{
  int iVar1;
  longlong lVar2;
  ulonglong uVar3;
  undefined1 uStack00000000;
  undefined4 uStack_10;
  int iStack_c;
  
  uVar3 = FUN_980618cc();
  iVar1 = *param_2;
  iStack_c = (int)uVar3;
  switch(iVar1) {
  case 1:
  case 2:
  case 3:
  case 4:
  case 5:
  case 7:
  case 9:
    if (iVar1 != 9) {
      FUN_980b1f40(iStack_c);
      FUN_980dbfc0(uVar3);
    }
    break;
  case 6:
                    /* WARNING: Bad instruction - Truncating control flow here */
    halt_baddata();
  case 8:
    *(ulonglong *)(iVar1 + 0x1f) = uVar3;
    FUN_980af838(&uStack_10);
    lVar2 = FUN_980b5488(ZEXT48(&uStack00000000) - 0x30,0xffffffff9819039c);
    if (-1 < (int)lVar2) {
      lVar2 = 0;
    }
    return lVar2;
  default:
    return 0xffffffff80300001;
  }
  return 0;
}


