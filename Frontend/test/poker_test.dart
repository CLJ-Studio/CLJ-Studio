import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/evaluador_poker.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_poker.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/repositorio_poker.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_mesa_poker.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_salas_poker.dart';

/// 300 manos al azar con el valor que les dio poker_mejor_valor() en
/// Postgres. El evaluador de la app tiene que dar exactamente lo mismo.
const _delServidor = <(String, int)>[
  ('3c 7s Ts Ah Qh 3d 5d', 1305760),
  ('Jd Jc Tc 8d Js Ah 9c', 3926528),
  ('As Ah Jh 9s 5c 2s Jc', 3062016),
  ('3h 3c 6d 3d 9s 2s Qc', 3393792),
  ('9c Qc 7s 5h 8h 6s 7d', 4784128),
  ('7d 8s Kc Ts Qs 3s 7h', 1563808),
  ('3h Tc Td 6d As 9h 4h', 1763680),
  ('Qh Kh Ad Js 6c 2h Ah', 2022576),
  ('7c Ac 9h 8c 3h 8h Jh', 1633168),
  ('Tc 9c 3c 8c Ts Jd Ad', 1764240),
  ('8h Th 6s 8d Js 9d Ts', 2788096),
  ('Th 2h Js 5d 4s 2c Kh', 1235872),
  ('Th Qd 3d Kh Jc 8c 9d', 5046272),
  ('4h 9d 5d 3c Qs Ks 9h', 1694800),
  ('Qc 9d Kh Td 6s Tc 8h', 1760400),
  ('Qd 6c Tc Qh Ts Ks 9d', 2927872),
  ('Ac 8h 8c 5s 6d 6h 2s', 2649600),
  ('2d 4h Qh Jd 9h Th 9c', 1690528),
  ('7c 5s 6s Ks 9c 9h Ts', 1694320),
  ('Ah 9c 8c Tc Qd 2d 6d', 969368),
  ('7s 9h 3d 9s Ks Kh Ts', 2988544),
  ('6s 9s 4c 8c Kd 9d 3s', 1693792),
  ('Qh 6h 9c 7c 3d 5s 8d', 4784128),
  ('4h 9s 2s 3h Ah Ad Jh', 2013504),
  ('Td 3h Jc 5s 5c 3c Ah', 2440704),
  ('2d As Td 6h Qd Qs 7d', 1895024),
  ('4h 2s 7s Qd Jh Js 9c', 1821040),
  ('Ks Kd 4s Td 5d 9d Jh', 1948304),
  ('4s Jd Ks Ts 6d 3h 8d', 899718),
  ('Qd 4d 4s Jh 6c Ts 8d', 1362848),
  ('8s 4h Th 5s Ac 2s 3d', 4521984),
  ('8s 3s 2c 7d Qh As 2h', 1240192),
  ('2h Ts 9d 7s Qc 6c 9s', 1690224),
  ('7s 3c 9c 9h Js Jc 4d', 2856704),
  ('4h Jh Th 5h 8c Jc 7h', 6006612),
  ('9h Jd 5d Qc Kh 3s Tc', 5046272),
  ('8h 2d 5s Qh 4c Ad As', 2017360),
  ('Td 2c 9s As Qh 5s 9d', 1698976),
  ('Kh Qc 2h 4s Qh Th 5h', 6146642),
  ('Ad Th 4s 4d Qd 4c 8s', 3468288),
  ('6h 8c Td 8d 3h 8s 6c', 6840320),
  ('4c 7d Ac 6s 9h 9c 8d', 1697904),
  ('6d 9h 4c 7s Th 9d 9s', 3778304),
  ('3c Th Ad 6h 3d 5h 5d', 2440704),
  ('2s 3h 9h Qh 7h 8d Td', 829831),
  ('Ad Qd 4c 2h 7d 4d Kc', 1371584),
  ('Tc Qc Js Td 5h 3c Jc', 2862080),
  ('Kh 6h Tc As Js Kd 5h', 1960864),
  ('Js 6d Ac 6h Qd Tc 4s', 1502384),
  ('3d Ad 6s Ac 8c 4d As', 4097536),
  ('Qc 2c As 7d Kd 4c Qh', 1895792),
  ('Qs 3d Ts 7s 6h Jh 3s', 1297312),
  ('6d 7s 4d 6s As 3s 2s', 6190642),
  ('8d Ah 6s Ac 2s 2c 3d', 3024896),
  ('5c 2h 6c 3c 3d Qc Tc', 6071891),
  ('Js 7d 7s 9h Jd Qs Qh', 2930944),
  ('Kh Jc 2d 8h 7s Jd 5h', 1824880),
  ('Jd 9h 8c Qc 3c As 7c', 969624),
  ('Ts Qc 6s 8s 6d 7d 2c', 1493632),
  ('Kc Kh 8c 2h 6d Ks 7h', 4032256),
  ('6d Kd Ah 3c 6c 8d 7s', 1502592),
  ('Jh 2h Td 7h 5s Tc 2c', 2763520),
  ('Kd 3c 4d Jc Ad Kc 2d', 1960768),
  ('4s Th 7d Jd Qh Kc 6c', 904103),
  ('2h 8c Jh 4s 7d 8d 8s', 3716864),
  ('8s 5c Ah 8d Qd 5d 4s', 2645504),
  ('4c Td 2h Qd Kh Ad Qc', 1895840),
  ('Tc 8h 6s 4h 5d 2h Kd', 895077),
  ('6h Td 9d 8d 6s 7s 4s', 4849664),
  ('Qs Jh 3h 4c Tc 2d Qh', 1882688),
  ('Ts 6s 7h Qs Th 7s 2c', 2784256),
  ('Qd 2s Qs 5c 9d 2c 5d', 2906368),
  ('Qc Ts 4h Kc 8h Kh 7c', 1952384),
  ('Ad 5d Tc 6h 7h 5s 7c', 2579968),
  ('7d 9h Qs Ad Tc 9d Qc', 2924032),
  ('Jh 6c 5s 4d Qs 8d 4h', 1362816),
  ('9c 2s 7d Th Ks 8d 2d', 1235600),
  ('Qs 4c 3h 6c 7c Td 6s', 1493616),
  ('4s Kh Kc 3d 2h Td 5h', 1942848),
  ('Ks Jh 6c Js 2d 8h 8s', 2854144),
  ('Td Th Qh Qd 4d Ts 3d', 6995968),
  ('3h 4h Kd 8s 7h Tc 6s', 895094),
  ('6c 2d Kc Jh Qd 5s 4d', 904037),
  ('6d Ac Td Ad 7d 4s 8s', 2009200),
  ('5s Kc Qs 2s Jd Qh 9d', 1891216),
  ('8c 7d Ah Td 4d Kd Th', 1764736),
  ('2h 4c 7s Td 4h 4d Ac', 3467776),
  ('3c Ts Qd Kh Qh 2s 7c', 1890928),
  ('3s 7c 6c 5h Td 4h Jd', 4653056),
  ('Jc 5c 4s 3d 7s 9c As', 964981),
  ('Kd 3s 8s 6s Jc 6c Qh', 1498288),
  ('3c 7d 9d 9c Ac Tc Th', 2792960),
  ('5c 7d Qc 9h Jh Ad 3h', 969623),
  ('3s Ah 3h 9c 6c 6s Qd', 2506240),
  ('5d 4d 7s 8c Ts Tc 7h', 2783232),
  ('7s Kd Qd 9c 8h Ac 4c', 973976),
  ('5s 9h 5d Ks 7d Kc 8d', 2971904),
  ('Ac Jh 8s 5h 4h 9s Js', 1829248),
  ('Qd Kc 4s 8c 6h 7h 3c', 903286),
  ('7s 6h 9s 6s 4h Td Qs', 1493648),
  ('6h 5d 7h 4h Tc 3c Ac', 4653056),
  ('6d Js 9h Qs 8h Kc 2h', 904088),
  ('Tc Kh 7h Qc 8d Ah 3d', 973992),
  ('Qc Ah 9c Ac Qs Qd Td', 7135232),
  ('Th 5h 8c 7d Qh 7h 2c', 1559168),
  ('8h Kd 4c 2s 6h Tc Ks', 1943648),
  ('6s 4s 7h Jh Qh Jc 8d', 1820784),
  ('Ah 9d Ad 7h 2s 2d 5d', 3025152),
  ('Qs 3c Qd 6h 7s 2h 5h', 1865296),
  ('Ad 9h Ts 6h Jc Qs 7c', 969641),
  ('3h Tc Ks 5s Td 2s 3d', 2768128),
  ('4h 7h 5d 9h 5h Jd Qc', 1428368),
  ('4d Kh 6c 3h Js 8d Ad', 973702),
  ('Th Qc Jh Tc 4s 3d 2h', 1755968),
  ('6h 8d 2d 4c Tc Kd Ts', 1759328),
  ('5d 9d Qd Ah 7h Kc 7d', 1568192),
  ('7s Jd 9d 6s 9c Ac As', 3054336),
  ('2d Qh 9c 4s 2h 9d 7c', 2698240),
  ('6s As 9h 5s 7c 6h Ts', 1501840),
  ('Kd 8h 6c 5h Jh 2c 8d', 1629024),
  ('3s Kd Ad Qh Qd Ts Qc', 3992832),
  ('Td Ah 6c 9d Jc 3h Ts', 1764240),
  ('Th Jd 7s 9c Ah Qd 7h', 1567920),
  ('7c 4c 3s Tc Ad 6s Th', 1763168),
  ('Th 8s Qs 3d Jd 5h 2h', 834181),
  ('9h 5c 5h 8c Ts Th 4s', 2775296),
  ('Ts 5h 6h Kh 9c 4s Tc', 1759584),
  ('Qc 7s 7c Qh 8h Td Jc', 2915072),
  ('Kd Td 5s 4h Jd Tc Kh', 2992896),
  ('4h Kd Ac 4s Qd Js 2c', 1371584),
  ('Ac Qd 2d 6h 6c 4c 4s', 2510336),
  ('6h Td Ks 7d 4s 9h 4d', 1366672),
  ('4c Ks 2c As Ac Qc 4h', 3034368),
  ('8d Qh Jc 9c Td 2h 6c', 4980736),
  ('5d Ts 7c Td 3h 9h Qc', 1755504),
  ('Kc 8d 4h 7s Ah Kh Ts', 1960576),
  ('2d 9d 2s 2c 3d 7d Jh', 3324160),
  ('Kh Ks 6s 7h 2h 4d Ts', 1943392),
  ('5s 3h 8c Qd Ah Ac 4d', 2017360),
  ('5c 5d Qd 9c 5h 7c 4d', 3524864),
  ('Td 8c Kd Ad 9h 7c Kh', 1960592),
  ('5h 6c Qs Kc 9s Tc Jd', 5046272),
  ('9d 3h 5h Kc 5s 3c Ad', 2440704),
  ('7d Kh Qc Jc Ks 4d 3c', 1952624),
  ('4c 5h Qh 8c 5s As 2h', 1436800),
  ('Tc 4h Qh Qs 6h 6d 7c', 2910720),
  ('8h 2s 9d Th 9h 6h 7d', 4849664),
  ('9c 4s 3d 4h Tc 5d 7d', 1354096),
  ('9h 8s Jd Qs Jh 2c Ks', 1825936),
  ('Qd Tc 7s As 6s Qc 3h', 1895024),
  ('9h Ac 7d Td Th Kc 3d', 1764752),
  ('6h 6d 2d 3h Jh Ah 3s', 2506240),
  ('Th 9s Js 3d 8s Qh Ah', 4980736),
  ('9h Jc 9d Td 2h 4h 7s', 1686128),
  ('4s 2h 3d 8h 3h 4d Td', 2374144),
  ('6s 2h 2d Kc 3s Jd Th', 1235872),
  ('3c Kd 7h Kh 4h 6c 9d', 1939296),
  ('5c 7s Kh 9h Ks Ac 8h', 1960320),
  ('5c Ts 7s 8d 2d 9c Ac', 960903),
  ('Jd 4c 9s 5s 3c Jh 9d', 2856192),
  ('Jh 8s 9d Th 2h 9c 5h', 1686144),
  ('8s Kd 2d Th 9h 4s 6d', 895366),
  ('5c Th 7s 6h 8c Jh 2h', 764022),
  ('7d Jd Th 4d Ah 3c Js', 1829488),
  ('7c 5h Jh 3s Tc 4d 9h', 764277),
  ('8h 3c 3d 8d Ac 2s 5c', 2637312),
  ('5s 2c 6s As 4d Th 6h', 1501776),
  ('7c 3h 6s 4d 2d 5h Kh', 4653056),
  ('Qs Kh Tc 3c 9s Ah Qd', 1895840),
  ('2d 7d Ks 9h Ts Qs Ac', 973993),
  ('5s Qh Ad 9d 2c 6d 3h', 969061),
  ('4d Qh 3s 6h 5h 2s 6d', 4587520),
  ('Jc Qh 2d 9d 6s 3s Ks', 904086),
  ('Kd Td 4d Tc Qs Th Jh', 3857408),
  ('Td 5c 9c 2c Ac 7d 5d', 1436304),
  ('Td 8h 9h 3h 5c 2d 2s', 1223040),
  ('8d 8s Tc 3h 9s Qc Jc', 4980736),
  ('4c 4d 5c Ad Tc 5s Ts', 2776576),
  ('As 7h 8h 6h Qh Kc 4d', 973959),
  ('9h 3h 2h 7d 3s 4s Js', 1292656),
  ('Th Ah 5c 9d Ks 4h Qc', 973993),
  ('Ac 7s 4c 9c Tc 3c 4s', 6203715),
  ('2s 8s 3h Ks 9c Qs 8d', 1629328),
  ('Qd Js 7h Ts 7d 3h Qc', 2915072),
  ('Jh 2h Qh 6s 5c 3c 8s', 833637),
  ('5c 6c Jd Qc Js As Kc', 1830336),
  ('4c 6c Kc Td 2s 2h 7h', 1235568),
  ('Kc 4c Kh 9h Jh 3d 5c', 1947984),
  ('Qd 9d As 4d Jd Ts Ac', 2018208),
  ('9d 3c 3s 4s 2s Jc Th', 1292944),
  ('6c 4h 8d 6s 2h 9s Jd', 1489280),
  ('6d 4h 8s Qs As 2s 9s', 6211970),
  ('Jh 3c 3d 5d 7s 9s 3s', 3389696),
  ('8s 6h 9s Ah Kd 6c 6s', 3599616),
  ('9s Kc Jc 8d 9d 6d 7s', 1694592),
  ('4d 3d Jc Tc 2h 5h Kd', 899668),
  ('Ks 6d Kh As 8h 5d Ac', 3069952),
  ('Qd 7s 4d 3d 5d 8s 4s', 1362032),
  ('Jd 7h Qh Td 8h 5h Jc', 1821312),
  ('Tc 6c Td Ah 8s Ks 6s', 2780672),
  ('7d 9s 5c 4c Ts 6c 2d', 694117),
  ('Kc Jc 5s 6c 4d 8c Qd', 904070),
  ('Jh 4s 9s 8s Qs 9c Qc', 2923264),
  ('2c Jc 6c Kc 2d Jd Ts', 2829568),
  ('7h Tc 6c 8d 5d Ks Qs', 903815),
  ('Td Ts 6d Qd Jc Ad 7d', 6212214),
  ('7d As 8s Th 5d 2s 8d', 1632880),
  ('Th 8c 8s Jc 7c 5c Tc', 6006901),
  ('Jh 8s 7d Kc 2h 3d 5c', 899189),
  ('5h 4c 9c Jc 8h 9d 4d', 2706176),
  ('8c Ts 5s 7c 2h Td 3h', 1738576),
  ('3d 3c 5h 8h Ad 9h Jd', 1305488),
  ('7d Qs Th Ad 3d 8d 5c', 969351),
  ('7s 6c 2s 3d 3s 7h Qd', 2571264),
  ('4h 9h Qs 8d 3d Qh Kc', 1890688),
  ('5s Tc 9c 7h Jd 4c 3c', 764277),
  ('3h 7d 5c 4h 9s 9h 3d', 2701056),
  ('Tc Ad 8c As 4s 3h 2h', 2009152),
  ('Qc 9h 8c 3s 9s 9c 2c', 3786752),
  ('9s 9d 7d Kc 3d 2c 8d', 1693808),
  ('4c 8c Qs 3s 6s Kh Td', 903814),
  ('Th 5c 8c 3d 7d 4d 2s', 690004),
  ('4h Jd Ad 6c 6s 8c 3d', 1502080),
  ('Ks 5d 7c As 3s 8d Qs', 973959),
  ('3h Js Ah Jc 6s 7s 8c', 1828976),
  ('Jc Jh 6c 5d Kc Jd Th', 3922432),
  ('4c Th 8d 6s 2d Tc Jc', 1751136),
  ('6s Th 9h 6d 8d Ac 5h', 1501840),
  ('Kh Ah Kd Jh 9s 4d 7d', 1960848),
  ('Th 6c 6s Ad 3c Jd 5c', 1502112),
  ('2s 5s Jd Ah 7h Ks 7s', 1568176),
  ('Kd Qs 3c Qd 7h 8h Qh', 3987456),
  ('8c Jc 9h Jd 8s Qc 3d', 2853888),
  ('7c 8c As Qc 9s Jh 7s', 1567920),
  ('Js 8s 7d 2s Ah Ad Kc', 2022272),
  ('Ad 6s 9d 2s 7c 8d 9h', 1697904),
  ('2d Jd 2h Kh 6d Td Kd', 6142562),
  ('Ad 2c 3c 7h 8c 6s 8s', 1632096),
  ('6c Kh 6s 2s 5h Kc 2c', 2974976),
  ('3s 5d 4c 2c Kh 7c Jc', 898900),
  ('Td 9h 3d Qc Jc Ac Th', 1764528),
  ('Qs Jc 2c 6d 4s 3d 8d', 833636),
  ('5d 3c Ks 3s 3d As Jh', 3403008),
  ('Kc Kd 8s 2d 4s 9s Tc', 1943936),
  ('Kc 2h As 6d 8d 7c Tc', 973447),
  ('Qc Ad 9s 5s 2c 8d 6c', 969094),
  ('4h 6h Qs Td 4d Jd 8h', 1362848),
  ('Kh 2c 3s 9h Js 8d 9d', 1694592),
  ('9s Qs Ad 4h 2s 6d 3d', 969060),
  ('Ad 4s 8c 5s 6h 9h Th', 960902),
  ('Jc 4h 5h 7s 4d Ks 6d', 1366896),
  ('2h 3d 5s 9h 8s 3s 7c', 1284208),
  ('8h 3s 2s 7c Js Qd 3h', 1297280),
  ('6h Tc 5d 5s 7h 6s 3h', 2513408),
  ('6c Td Tc 3c Ad 3s Ks', 2768384),
  ('5d 9h Tc 7d 4s 4d 4h', 3451136),
  ('5s Tc 6s Qc 3c 8s Ah', 969350),
  ('Jh Qh 9d 7c 5s Kc 4c', 904087),
  ('7c 9d 3s Qs Jd 4s Jc', 1821040),
  ('6d Td 2c Tc 7d 5d 6h', 2778880),
  ('9d Qs 2d 6c 4h 6h 9h', 2714624),
  ('8h Ad Kh 3d 5h 6c 3c', 1305984),
  ('6s Qc 8d 3s 9d 7s 6d', 1493376),
  ('6c 4s Ks 2c 3s 6d 8c', 1497152),
  ('3h 5s Qh Ad Td 2s 2h', 1240224),
  ('7s 5s 2h Qs Ac 3d 6s', 968549),
  ('9c Th 8d Qc 7h Td Jc', 4980736),
  ('5d 2d 7d Qc Js Kh 9c', 904087),
  ('Qc 9c Ks 8c 2c Qs Qh', 3987712),
  ('7h 7c 5s Td 6s Tc Qs', 2784256),
  ('Th 7d 8h Td 3h Qs Qh', 2926592),
  ('As Ad 2h 8c 9h Qc 2c', 3025920),
  ('Qh Jd 2d 9d 4h Qd As', 1895312),
  ('8h 3c Kh Qh 7d Ad 6s', 973959),
  ('3c 5c 8c 5d Qh 5h 6h', 3524608),
  ('5h 9h Qc 2s 3c 2d Th', 1231504),
  ('9d 7d 4c 8h Qh 4s 5s', 1362304),
  ('Ks Jd 6c 4c Ah 8c 6d', 1502640),
  ('8c Ac Tc Ad 5s 3h 8h', 3049984),
  ('8s 7c 5h Jd Td As Js', 1829504),
  ('Ah Kh 9c 6s 7s Ad 5c', 2021744),
  ('Kd Kc 7h Tc 3h 5s 6h', 1943392),
  ('4c 3h 9h Ac 5d Kd Kc', 1960272),
  ('6c Jc 8d 9h As 2d 6h', 1502096),
  ('Kd 6d Ks 3h Qs 2d 6h', 2976768),
  ('Ah 9h 7h Ks 3s 8s Th', 973464),
  ('Ts 8c Kc 7s 8d 3h 3c', 2637056),
  ('Ks Qc 6h 3c Kh 2c Th', 1952352),
  ('4s 5c 7s Js Ah 5d 6s', 1436528),
  ('Jc Qc 6h 2s Ad 6d 4d', 1502384),
  ('Js 6h Ah 9d Ad 9h Th', 3054336),
  ('As Kh Kc 3s Tc 4s 6h', 1960544),
  ('Ac 6h 8h 2s 4c Ah 3h', 2000448),
  ('Jc 7c 8h As Tc Ks 2s', 973736),
  ('Kc Tc 2s 3s 2c 2h Kh', 6475776),
  ('2d Qs 7s Ad 4s 2h Kd', 1240512),
  ('9c 2c Ah 2h Jh 3d 9s', 2698752),
  ('Ah 2c 5s As Jd 4h 9c', 2013520),
  ('5s 5d 2d 7c 9s Ah Ac', 3037440),
  ('2d 6c Th Ts 9d 9s Ks', 2792704),
];

final _hora = DateTime.utc(2026, 10, 18, 15);

Map<String, dynamic> _asiento(
  int posicion,
  String nombre,
  int fichas, {
  bool afuera = false,
}) => {
  'posicion': posicion,
  'usuario_id': 'u$posicion',
  'nombre': nombre,
  'avatar_path': null,
  'fichas': fichas,
  'afuera': afuera,
};

Map<String, dynamic> _jugador(
  int posicion, {
  int ronda = 0,
  int aportado = 0,
  bool retirado = false,
  String? accion,
  List<String>? vistas,
  int? valor,
}) => {
  'posicion': posicion,
  'usuario_id': 'u$posicion',
  'apuesta_ronda': ronda,
  'aportado': aportado,
  'retirado': retirado,
  'todo': false,
  'ultima_accion': accion,
  'cartas_vistas': vistas,
  'valor': valor,
};

/// Como lo devuelve poker_estado(): Ana (yo, asiento 0) y Beto (asiento 1).
Map<String, dynamic> _estado({
  int? yo = 0,
  Map<String, dynamic>? mano,
  List<Map<String, dynamic>>? asientos,
  List<Map<String, dynamic>> jugadores = const [],
  List<String>? misCartas,
}) => {
  'ahora': _hora.toIso8601String(),
  'sala': {
    'id': 's1',
    'nombre': 'Mesa de prueba',
    'ciega_chica': 10,
    'ciega_grande': 20,
    'fichas_iniciales': 1000,
    'segundos_turno': 30,
  },
  'yo': yo,
  'asientos':
      asientos ??
      [_asiento(0, 'Ana Perez', 980), _asiento(1, 'Beto Rojas', 960)],
  'mano': mano,
  'jugadores': jugadores,
  'mis_cartas': misCartas,
};

Map<String, dynamic> _mano({
  String fase = 'preflop',
  int? turno = 0,
  int apuesta = 40,
  int bote = 60,
  List<String> comunitarias = const [],
  Duration vence = const Duration(seconds: 25),
  List<Map<String, int>>? resultado,
}) => {
  'id': 'm1',
  'numero': 3,
  'boton': 1,
  'fase': fase,
  'comunitarias': comunitarias,
  'turno': fase == 'terminada' ? null : turno,
  'vence_en': fase == 'terminada' ? null : _hora.add(vence).toIso8601String(),
  'apuesta': apuesta,
  'subida_minima': 20,
  'bote': bote,
  'resultado': resultado,
  'terminada_en': fase == 'terminada' ? _hora.toIso8601String() : null,
};

class _RepositorioFalso implements RepositorioPoker {
  _RepositorioFalso(this.datos, {this.mesas = const []});

  Map<String, dynamic> datos;
  List<SalaPoker> mesas;
  final jugadas = <String>[];
  final sentadas = <String>[];
  final creadas = <String>[];
  int repartos = 0;
  int vencidos = 0;
  int vueltas = 0;
  int recargas = 0;
  int levantadas = 0;

  @override
  Future<EstadoMesaPoker> estado(String sala) async =>
      EstadoMesaPoker.desdeMapa(datos);

  @override
  Future<List<SalaPoker>> salas() async => mesas;

  @override
  Future<String> crearSala(String nombre, int ciegaGrande) async {
    creadas.add('$nombre:$ciegaGrande');
    return 'nueva';
  }

  @override
  Future<void> sentarse(String sala) async => sentadas.add(sala);

  @override
  Future<void> levantarse(String sala) async => levantadas++;

  @override
  Future<bool> empezarMano(String sala) async {
    repartos++;
    return true;
  }

  @override
  Future<void> jugar(String sala, String accion, {int monto = 0}) async =>
      jugadas.add('$accion:$monto');

  @override
  Future<bool> vencerTurno(String sala) async {
    vencidos++;
    return true;
  }

  @override
  Future<void> volver(String sala) async => vueltas++;

  @override
  Future<void> recargar(String sala) async => recargas++;

  @override
  VoidCallback escucharMesa(String sala, VoidCallback alCambiar) => () {};

  @override
  VoidCallback escucharSalas(VoidCallback alCambiar) => () {};
}

Future<void> _abrirMesa(WidgetTester tester, _RepositorioFalso repo) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaMesaPoker(
        salaId: 's1',
        repositorio: repo,
        sonidos: const SonidosMesa.mudos(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Pasa el tiempo de la mesa (el reloj interno va de a medio segundo).
Future<void> _esperar(WidgetTester tester, int milisegundos) async {
  for (var t = 0; t < milisegundos; t += 250) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  group('el evaluador', () {
    test('da lo mismo que el servidor en 300 manos al azar', () {
      expect(_delServidor, hasLength(300));
      for (final (cartas, valor) in _delServidor) {
        expect(
          EvaluadorPoker.mejorValor(cartas.split(' ')),
          valor,
          reason: cartas,
        );
      }
    });

    test('nombra las manos', () {
      String nombre(String cartas) =>
          EvaluadorPoker.nombre(EvaluadorPoker.mejorValor(cartas.split(' ')));

      expect(nombre('As Ks Qs Js Ts 2d 3c'), 'Escalera real');
      expect(nombre('9s 8s 7s 6s 5s 2d 3c'), 'Escalera de color');
      expect(nombre('9h 9d 9s 9c Kd 2s 3h'), 'Póker de nueves');
      expect(nombre('8h 8d 8s Kc Kd 2s 3h'), 'Full de ochos y reyes');
      expect(nombre('2h 7h 9h Jh Kh Ad Ac'), 'Color');
      // A-2-3-4-5: la escalera mas baja.
      expect(nombre('Ad 2c 3h 4s 5d Kc Qd'), 'Escalera');
      expect(nombre('Qd Qc Qh 4s 9d 2c 7h'), 'Trío de reinas');
      expect(nombre('Kd Kc 4h 4s 9d 2c 7h'), 'Doble par: reyes y cuatros');
      expect(nombre('Ad Ac 4h 5s 9d 2c 7h'), 'Par de ases');
      expect(nombre('Ad Kc 4h 5s 9d 2c 7h'), 'Carta alta');
    });

    test('lee las cartas como las guarda el servidor', () {
      final as = CartasPoker.carta('As')!;
      expect((as.rango, as.palo), (1, Palo.picas));
      final diez = CartasPoker.carta('Td')!;
      expect((diez.rango, diez.palo), (10, Palo.diamantes));
      final rey = CartasPoker.carta('Kh')!;
      expect((rey.rango, rey.palo), (13, Palo.corazones));
      expect(CartasPoker.carta('Zz'), isNull);
    });
  });

  group('el estado de la mesa', () {
    test('sabe cuanto falta, el minimo para subir y el maximo', () {
      final estado = EstadoMesaPoker.desdeMapa(
        _estado(
          mano: _mano(),
          jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 40)],
          misCartas: ['As', 'Kd'],
        ),
      );
      expect(estado.esMiTurno, isTrue);
      expect(estado.falta, 20);
      expect(estado.puedoPasar, isFalse);
      expect(estado.paraIgualar, 20);
      expect(estado.subidaMinimaTotal, 60);
      expect(estado.maximoTotal, 1000);
      expect(estado.miMano, isNull, reason: 'sin flop no hay mano que nombrar');
    });

    test('cuenta el reloj con la hora del servidor', () {
      final llego = DateTime(2030, 1, 1, 12);
      final estado = EstadoMesaPoker.desdeMapa(
        _estado(mano: _mano(vence: const Duration(seconds: 20))),
        recibidoEn: llego,
      );
      // Aunque el reloj del telefono este en otro año.
      expect(
        estado.restante(llego.add(const Duration(seconds: 5))).inSeconds,
        15,
      );
      expect(
        estado.restante(llego.add(const Duration(seconds: 40))),
        Duration.zero,
      );
    });

    test('nombra mi mano con lo que hay en la mesa', () {
      final estado = EstadoMesaPoker.desdeMapa(
        _estado(
          mano: _mano(fase: 'flop', comunitarias: ['Ac', '7d', '2s']),
          jugadores: [_jugador(0), _jugador(1)],
          misCartas: ['As', 'Kd'],
        ),
      );
      expect(estado.miMano, 'Par de ases');
    });
  });

  group('la mesa', () {
    testWidgets('en mi turno igualo y subo', (tester) async {
      final repo = _RepositorioFalso(
        _estado(
          mano: _mano(),
          jugadores: [
            _jugador(0, ronda: 20),
            _jugador(1, ronda: 40, accion: 'subir'),
          ],
          misCartas: ['As', 'Kd'],
        ),
      );
      await _abrirMesa(tester, repo);

      expect(find.textContaining('Tu turno'), findsOneWidget);
      expect(find.text('Sube'), findsOneWidget, reason: 'lo que hizo Beto');
      await tester.tap(find.text('Igualar 20'));
      await tester.pump();
      expect(repo.jugadas, ['igualar:0']);

      await tester.tap(find.text('Subir'));
      await tester.pumpAndSettle();
      expect(find.text('Subir a 60'), findsOneWidget);
      await tester.tap(find.text('Subir a 60'));
      await tester.pumpAndSettle();
      expect(repo.jugadas, ['igualar:0', 'subir:60']);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('si no es mi turno, dice de quien es', (tester) async {
      final repo = _RepositorioFalso(
        _estado(
          mano: _mano(turno: 1),
          jugadores: [_jugador(0, ronda: 40), _jugador(1, ronda: 20)],
          misCartas: ['As', 'Kd'],
        ),
      );
      await _abrirMesa(tester, repo);

      expect(find.textContaining('Turno de Beto'), findsOneWidget);
      expect(find.text('Retirarme'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reparte cuando hay dos sentados y ninguna mano', (
      tester,
    ) async {
      final repo = _RepositorioFalso(_estado());
      await _abrirMesa(tester, repo);
      await _esperar(tester, 1200);

      expect(repo.repartos, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vence el turno de quien no juega', (tester) async {
      final repo = _RepositorioFalso(
        _estado(
          mano: _mano(turno: 1, vence: const Duration(seconds: -5)),
          jugadores: [_jugador(0, ronda: 40), _jugador(1, ronda: 20)],
          misCartas: ['As', 'Kd'],
        ),
      );
      await _abrirMesa(tester, repo);
      await _esperar(tester, 1200);

      expect(repo.vencidos, greaterThanOrEqualTo(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('al final dice quien gano y con que', (tester) async {
      final full = EvaluadorPoker.mejorValor('Kh Kd Ks 3c 3d 9s 2h'.split(' '));
      final repo = _RepositorioFalso(
        _estado(
          mano: _mano(
            fase: 'terminada',
            comunitarias: ['Ks', '3c', '3d', '9s', '2h'],
            bote: 340,
            resultado: [
              {'posicion': 1, 'monto': 340},
            ],
          ),
          jugadores: [
            _jugador(0, aportado: 170, vistas: ['Ah', 'Qh'], valor: 1),
            _jugador(1, aportado: 170, vistas: ['Kh', 'Kd'], valor: full),
          ],
          misCartas: ['Ah', 'Qh'],
        ),
      );
      await _abrirMesa(tester, repo);

      expect(
        find.text('Beto gana 340 con Full de reyes y treses.'),
        findsOneWidget,
      );
      expect(find.text('+340'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sola en la mesa: se juega desde 2, e invito', (tester) async {
      final enlaces = <Uri>[];
      final repo = _RepositorioFalso(
        _estado(asientos: [_asiento(0, 'Ana Perez', 1000)]),
      );
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaMesaPoker(
            salaId: 's1',
            repositorio: repo,
            sonidos: const SonidosMesa.mudos(),
            abrirEnlace: (enlace) async {
              enlaces.add(enlace);
              return true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('con 2 ya se juega'), findsOneWidget);
      await _esperar(tester, 1200);
      expect(repo.repartos, 0, reason: 'sola no se reparte');

      await tester.tap(find.text('Invitar por WhatsApp'));
      await tester.pump();
      expect(enlaces.single.host, 'wa.me');
      expect(
        enlaces.single.queryParameters['text'],
        contains('Mesa de prueba'),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('mirando, me puedo sentar', (tester) async {
      final repo = _RepositorioFalso(_estado(yo: null));
      await _abrirMesa(tester, repo);

      await tester.tap(find.text('Sentarme'));
      await tester.pump();
      expect(repo.sentadas, ['s1']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sentado afuera, vuelvo a jugar', (tester) async {
      final repo = _RepositorioFalso(
        _estado(
          asientos: [
            _asiento(0, 'Ana Perez', 500, afuera: true),
            _asiento(1, 'Beto Rojas', 960),
          ],
        ),
      );
      await _abrirMesa(tester, repo);
      await tester.tap(find.text('Volver a jugar'));
      await tester.pump();
      expect(repo.vueltas, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sin fichas, recargo las de la mesa', (tester) async {
      final repo = _RepositorioFalso(
        _estado(
          asientos: [
            _asiento(0, 'Ana Perez', 0),
            _asiento(1, 'Beto Rojas', 2000),
          ],
        ),
      );
      await _abrirMesa(tester, repo);
      await tester.tap(find.text('Recargar 1.000'));
      await tester.pump();
      expect(repo.recargas, 1);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('las salas', () {
    final mesa = SalaPoker.desdeMapa({
      'sala_id': 's1',
      'nombre': 'Mesa de Beto',
      'creador': 'Beto Rojas',
      'ciega_chica': 10,
      'ciega_grande': 20,
      'fichas_iniciales': 1000,
      'jugadores': 3,
      'en_juego': true,
      'mia': false,
    });

    Future<void> abrir(WidgetTester tester, _RepositorioFalso repo) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaSalasPoker(
            nombre: 'Ana Perez',
            repositorio: repo,
            sonidos: const SonidosMesa.mudos(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('lista las mesas y me siento en una', (tester) async {
      final repo = _RepositorioFalso(_estado(), mesas: [mesa]);
      await abrir(tester, repo);

      expect(find.text('Mesa de Beto'), findsOneWidget);
      expect(find.text('3/6 · jugando'), findsOneWidget);
      await tester.tap(find.text('Sentarme'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(repo.sentadas, ['s1']);
      expect(find.byType(PantallaMesaPoker), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('creo una mesa con mi nombre y las ciegas', (tester) async {
      final repo = _RepositorioFalso(_estado());
      await abrir(tester, repo);

      expect(find.textContaining('No hay mesas abiertas'), findsOneWidget);
      await tester.tap(find.text('Crear una mesa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25/50'));
      await tester.pump();
      await tester.tap(find.text('Crear y sentarme'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(repo.creadas, ['Mesa de Ana:50']);
      expect(find.byType(PantallaMesaPoker), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
