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
Nous compilons l'entièreté du projet en double cliquant sur `Compile Design`. Une fois compilé, nous allons sur l'outil de programmation du FPGA en allant dans `Tools > Programmer`. 

Le bouton `Auto Detect` est grisé, il faut donc cliquer sur `Hardware Setup` et choisir le bon _hardware_, nous c'était le `DE-SoC [USB-1]`. Ensuite, nous cliquons sur `Auto Detect`, puis un pop-up s'affiche et nous choisissons `5CSEBA6`. 

Ensuite nous chargons le bitstream en faisant clic-droit sur la puce `> Edit > Change File` et en Sélectionnant le fichier `.sof` dans le dossier `output_files`. 

Nous cochons la case `Program/Configure`.

![Programmation de la carte](/Tutoriel-Quartus/img/programmer2.png)

Enfin nous programmons la carte en appuyant sur `Start`.

### Ça fonctionne ?
Oui, cela fonctionne mais la LED est allumée lorsque le bouton poussoir est relâché et s'éteint lorsqu'il est enfoncé or c'est l'inverse que nous souhaitons.

| ![Comportement de la LED avec le bouton relâché](/Tutoriel-Quartus/img/card1.jpeg) | ![Comportement de la LED avec le bouton enfoncé](/Tutoriel-Quartus/img/card2.jpeg) | 
|:---:|:---:|
| Comportement de la LED avec le bouton relâché | Comportement de la LED avec le bouton enfoncé |

### Le comportement est inversé! La LED est allumée par défaut et s'éteind lorsque l'on appuie sur l'encodeur. On voulait l'inverse. Modifiez le VHDL, compilez, programmez.

Ici, la sortie dépend uniquement de l'entrée c'est-à-dire de l'état du bouton poussoir, ainsi nous pouvons inverser le comportement de la LED en utilisant une porte logique `NOT`. Le code VHDL devient alors :

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
    led0 <= NOT pushl;
end architecture rtl;
```