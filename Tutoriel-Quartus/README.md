# TP1 : Tutoriel Quartus
Le TP1 a pour objectif de se familiariser avec Quartus et le langage VHDL en concevant, compilant et programmant des circuits simples sur une carte FPGA.

En TD, nous avons utilisé le logiciel Modelsim pour simuler vos composants VHDL. Pour les tester sur FPGA, nous aurons besoin du logiciel Quartus Prime.

## Branchement de la carte
Pour fonctionner, la carte doit être alimentée. Le courant fourni par le port USB n'est pas suffisant, il faut ajouter une alimentation extérieure.

La carte est programmée par le port USB nommé `USB BLASTER II`. Il se situe du même côté que le connecteur d'alimentation et que le port HDMI. La carte ne peut pas être programmée par les autres ports USB.

![Emplacement du port USB nommé `USB BLASTER II` sur la carte.](/Tutoriel-Quartus/img/usb_blaster.png)

## Création d'un projet
Sur Quartus, nous créeons un projet du nom de `tuto_fpga` en veillant bien à choisir comme FPGA cible le `5CSEBA6U23I7`.

## Création d'un fichier VHDL
Nous créons un nouveau fichier VHDL du nom de `tuto_fpga` avec le code suivant :

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tuto_fpga is
    port (
        pushl : in std_logic;
        led0 : out std_logic
    );
end entity tuto_fpga;

architecture rtl of tuto_fpga is
begin
    led0 <= pushl;
end architecture rtl;
```

Ce composant simple permet d'allumer la LED0 lorsque le bouton poussoir de l'encodeur de gauche est enfoncé.

## Fichier de contraintes
* `LED0` est sur la broche `PIN_AG28`
* `pushl` est sur la broche `PIN_AH27`

Quartus ne peut pas connaître ces informations, il faut donc lui préciser.

Nous les configurations alors dans `Assignments > Pin Planner` après avoir double cliquer sur `Analysis & Synthesis`.

![Configuration des broches](/Tutoriel-Quartus/img/pin_planner.png)

## Compilation et programmation de la carte
