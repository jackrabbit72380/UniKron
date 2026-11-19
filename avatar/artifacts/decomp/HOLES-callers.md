# Who references the 73 `.text` holes

Direct `bl` sites anywhere in `.text`, plus 4-byte pointers in
`.rdata` (0x98000000+0x3000) and `.data` (0x9813c000+0x4000).
A hole with both counts at zero is dead code.

| function | bl call sites | data pointers | callers (readable = has C) |
| --- | ---: | ---: | --- |
| `0x9803da18` | 1 | 0 | 0x980959d0(readable) |
| `0x9803ee60` | 1 | 0 | 0x98043320(readable) |
| `0x9803f920` | 1 | 0 | 0x9803f920(readable) |
| `0x9803faa8` | 5 | 0 | 0x9803fb50(readable) 0x98043b70(readable) 0x98044e08(readable) 0x9804a010(readable) |
| `0x98042498` | 1 | 0 | 0x98043478(readable) |
| `0x98043b70` | 1 | 0 | 0x98044ce0(readable) |
| `0x9804a010` | 1 | 0 | 0x9804a010(readable) |
| `0x9804d2f8` | 2 | 0 | 0x9804d2f8(readable) 0x9804d9a8(readable) |
| `0x98055cd8` | 5 | 0 | 0x9804c7c0(readable) 0x98055cd8(readable) 0x980560e8(readable) 0x98056510(readable) |
| `0x98055ef8` | 6 | 0 | 0x9804c7c0(readable) 0x9804d2f8(readable) 0x9804df98(readable) 0x9804eca0(readable) |
| `0x98058268` | 4 | 0 | 0x98058268(readable) |
| `0x9805bd20` | 1 | 0 | 0x98042be0(readable) |
| `0x9805be30` | 1 | 0 | 0x98046780(readable) |
| `0x9805bef8` | 1 | 0 | 0x98046780(readable) |
| `0x9805c648` | 1 | 0 | 0x9804a4a0(readable) |
| `0x9805d154` | 1 | 0 | 0x9805b8a0(readable) |
| `0x9805e060` | 0 | 0 | - |
| `0x98061950` | 182 | 0 | 0x9803ac4c 0x9803ad38(readable) 0x9803c070(readable) 0x9803cce0(readable) |
| `0x98062658` | 59 | 0 | 0x9803cf10(readable) 0x9803d6d0(readable) 0x98041ab8(readable) 0x98044e08(readable) |
| `0x98065ca0` | 5 | 0 | 0x98064f68(readable) 0x9806af60(readable) 0x9806e940(readable) 0x98113474(readable) |
| `0x98072978` | 6 | 0 | 0x980727b8(readable) 0x98072c80(readable) 0x98072f08(readable) 0x98073128(readable) |
| `0x98075890` | 2 | 0 | 0x98075708(readable) |
| `0x98078670` | 2 | 0 | 0x98078d00(readable) 0x98079d68(readable) |
| `0x9807b318` | 1 | 0 | 0x9807ba10(readable) |
| `0x980813e8` | 2 | 0 | 0x9803c418(readable) 0x980f6400(readable) |
| `0x9808a118` | 5 | 0 | 0x9803e3e8 0x98043b70(readable) 0x9804fca0(readable) 0x9807ccd8(readable) |
| `0x9808c178` | 7 | 0 | 0x98042498(readable) 0x980773e0(readable) 0x98078d00(readable) 0x98078e40(readable) |
| `0x9808c258` | 2 | 0 | 0x980f1258(readable) 0x980f6148(readable) |
| `0x9808e288` | 1 | 0 | 0x98087790(readable) |
| `0x9808e2f0` | 1 | 0 | 0x9808e858(readable) |
| `0x98095140` | 9 | 0 | 0x98095a28(readable) |
| `0x98095858` | 2 | 0 | 0x98095a28(readable) |
| `0x9809f590` | 2 | 0 | 0x9810c4f0(readable) 0x9810eb18(readable) |
| `0x9809f610` | 1 | 0 | 0x98109718(readable) |
| `0x9809f6d8` | 1 | 0 | 0x980f0b20 |
| `0x9809f898` | 1 | 0 | 0x98109718(readable) |
| `0x9809fad8` | 1 | 0 | 0x98109718(readable) |
| `0x980af1b0` | 1 | 0 | 0x980b1eb0(readable) |
| `0x980b0238` | 1 | 0 | 0x980b14e8(readable) |
| `0x980b9da0` | 1 | 0 | 0x980dc7a0(readable) |
| `0x980ba720` | 2 | 0 | 0x980babe0(readable) |
| `0x980c2760` | 1 | 0 | 0x980c2b38(readable) |
| `0x980c8aa0` | 3 | 0 | 0x980c8ff8(readable) 0x980c9218(readable) 0x980d0218(readable) |
| `0x980d2fb0` | 1 | 0 | 0x980d3420(readable) |
| `0x980d54f0` | 2 | 0 | 0x980d5cc0(readable) 0x980d6388(readable) |
| `0x980e4ef0` | 1 | 0 | 0x980e6488(readable) |
| `0x980e5448` | 0 | 0 | - |
| `0x980f0480` | 6 | 0 | 0x980a4658(readable) 0x980c4100(readable) 0x980d2fb0(readable) |
| `0x980f0530` | 12 | 0 | 0x9803c180(readable) 0x980c35a0(readable) 0x980c4100(readable) 0x980c8950(readable) |
| `0x980f05a8` | 19 | 0 | 0x980c2f98(readable) 0x980c35a0(readable) 0x980c4100(readable) 0x980c5fc0(readable) |
| `0x980f0638` | 38 | 0 | 0x980c2f98(readable) 0x980c35a0(readable) 0x980c4100(readable) 0x980c5fc0(readable) |
| `0x980f0760` | 4 | 0 | 0x980c25a0(readable) 0x980e42c8(readable) 0x980e78f8(readable) |
| `0x980f07d8` | 1 | 0 | 0x980c35a0(readable) |
| `0x980f0888` | 12 | 0 | 0x980c3b30(readable) 0x980c9b20(readable) 0x980cb4f0(readable) 0x980d0b78(readable) |
| `0x980f0a50` | 3 | 0 | 0x980c9218(readable) 0x980e4aa0(readable) 0x980e4ef0(readable) |
| `0x980f0ad8` | 4 | 0 | 0x980d1e98(readable) |
| `0x980f0c40` | 1 | 0 | 0x980ba680(readable) |
| `0x980f2ab8` | 39 | 0 | 0x980e33c8(readable) 0x980f2bb8(readable) 0x980f2d10(readable) 0x980f3058(readable) |
| `0x98120c80` | 0 | 0 | - |
| `0x98125240` | 1 | 0 | 0x98120cf0(readable) |
| `0x9812ae50` | 2 | 0 | 0x98128108(readable) 0x98129738(readable) |
| `0x9812b010` | 1 | 0 | 0x98136ec0(readable) |
| `0x9812b440` | 1 | 0 | 0x98137d48(readable) |
| `0x9812b6d8` | 1 | 0 | 0x98137e20(readable) |
| `0x9812bd00` | 1 | 0 | 0x98138328(readable) |
| `0x981314b0` | 1 | 0 | 0x981384c8(readable) |
| `0x98132b10` | 1 | 0 | 0x98138820(readable) |
| `0x98138ab8` | 0 | 0 | - |
| `0x98139210` | 0 | 0 | - |
| `0x98139a18` | 0 | 0 | - |
| `0x98139c50` | 0 | 0 | - |
| `0x9813a290` | 1 | 0 | 0x98104c08(readable) |
| `0x9813b1c8` | 0 | 0 | - |

8 of 73 holes have neither a caller nor a data pointer: 0x9805e060 0x980e5448 0x98120c80 0x98138ab8 0x98139210 0x98139a18 0x98139c50 0x9813b1c8
