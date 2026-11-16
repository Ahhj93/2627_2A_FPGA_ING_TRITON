## Mini-Projet : Ecran Magique  

Ce petit projet en 3 séances nous propose de concevoir une version numérique du télécran, en utilisant la sortie HDMI de la carte DE10-Nano. Le _stylet_ numérique sera toujours déplacé par deux boutons, les deux encodeurs de la carte mezzanine.

Il est découpé en 4 sous-parties, qui ne sont volontairement pas très détaillées. Pour chaque partie, vous aurez à suivre la démarche suivante :
1. Concevoir un schéma pour répondre à la problématique
2. Implémenter la solution en VHDL
3. Simuler cette solution
4. Tester sur la carte

### Gestion des encodeurs
Dans cette partie, nous mettrons l'affichage de côté pour vous focaliser sur les encodeurs.

L'objectif est d'incrémenter la valeur d'un registre lorsque l'on tourne l'encodeur vers la droite, et de le décrémenter lorsqu'on le tourne vers la gauche. La taille du registre doit être configurable. On pourra choisir une taille de 10 dans cette partie pour afficher la valeur en binaire sur les LED.

Un encodeur renvoie deux signaux A et B en quadrature.

* Il y a deux conditions possible pour incrémenter le registre :
    1. Front montant sur A et B à l'état bas
    2. Front descendant sur A et B à l'état haut
* Il y a deux conditions possible pour décrémenter le registre :
    1. Front montant sur B et A à l'état bas
    2. Front descendant sur B et A à l'état haut

#### Détection des fronts
Pour détecter un front sur le signal A, on utilise deux bascules D placées en série et cadencées par la même horloge. À chaque front montant de l’horloge, une bascule D recopie son entrée D sur sa sortie Q, puis garde cette valeur jusqu’au front d’horloge suivant.

![](img/edge_detector.png)

Ainsi, la première bascule contient la valeur actuelle de A, et la seconde contient la valeur de A au coup d’horloge précédent. Le bloc « ??? » compare ces deux valeurs :
* si A valait 0 avant et vaut 1 maintenant, on a un front montant
* si A valait 1 avant et vaut 0 maintenant, on a un front descendant
* si les deux valeurs sont identiques, A n’a pas changé et il n’y a pas de front.

La sortie E passe à 1 pendant un seul cycle d’horloge à chaque front détecté. Cela permet de modifier le compteur une seule fois par cran de l’encodeur.

La première bascule a aussi un rôle de synchronisation. Les signaux de l’encodeur viennent de l’extérieur et ne sont pas synchronisés avec l’horloge du FPGA. En les faisant passer par une bascule, on évite des comportements instables.

Pour connaître le sens de rotation, on applique cette structure aux deux voies A et B. On regarde ensuite l’état de l’autre voie au moment du front :
* incrémentation : front montant sur A avec B = 0, ou front descendant sur A avec B = 1  
![](img/incr.png)
* décrémentation : front montant sur B avec A = 0, ou front descendant sur B avec A = 1  
![](img/decr.png)

#### Implémentation de la solution en VHDL
Le schéma suivant nous est proposé pour implémenter la solution en VHDL. Cette implémentation permet de mieux comprendre le fonctionnement de l'encodeur.

![](img/encoder_circuit.png)

Nous implémentons le composant `encoder` dans le fichier `encoder.vhd`. Il prend en entrée les deux voies A et B de l'encodeur, ainsi que l'horloge et le reset. Il fournit en sortie un vecteur de LED représentant la valeur du compteur.

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder is
    generic (
        -- 5000000 @ 50 MHz = 100 ms
        -- 500000 @ 50 MHz = 10 ms
        PERIOD_S_EN : natural := 500000;
        WIDTH : natural := 10
    );
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;
        i_A     : in std_logic;
        i_B     : in std_logic;
        o_leds  : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity encoder;

architecture rtl of encoder is
    signal s_en : std_logic := '0';

    signal r_a_cur  : std_logic := '0';
    signal r_a_prev : std_logic := '0';
    signal r_b_cur  : std_logic := '0';
    signal r_b_prev : std_logic := '0';

    signal s_a_rising  : std_logic;
    signal s_a_falling : std_logic;
    signal s_b_rising  : std_logic;
    signal s_b_falling : std_logic;

    signal s_clockwise     : std_logic;
    signal s_cntclockwise  : std_logic;

    signal r_cnt : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
    -- Diviseur de fréquence pour avoir 100ms
    divider : process(i_clk, i_rst_n)
        variable counter : natural range 0 to PERIOD_S_EN-1 := 0;
    begin
        if (i_rst_n = '0') then
            counter := 0;
            s_en <= '0';
        elsif (rising_edge(i_clk)) then
            if (counter = PERIOD_S_EN-1) then
                counter := 0;
                s_en <= '1';
            else
                counter := counter + 1;
                s_en <= '0';
            end if;
        end if;
    end process divider;

    -- Echantillonage A et B
    sampling : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_a_cur  <= '0';
            r_a_prev <= '0';
            r_b_cur  <= '0';
            r_b_prev <= '0';
        elsif (rising_edge(i_clk)) then
            if (s_en = '1') then
                r_a_cur  <= i_A;
                r_a_prev <= r_a_cur;
                r_b_cur  <= i_B;
                r_b_prev <= r_b_cur;
            end if;
        end if;
    end process sampling;

    -- Détection fronts
    s_a_rising  <= r_a_cur and not r_a_prev;
    s_a_falling <= not r_a_cur and r_a_prev;

    s_b_rising  <= r_b_cur and not r_b_prev;
    s_b_falling <= not r_b_cur and r_b_prev;

    -- Sens
    s_clockwise    <= (s_a_rising and not r_b_cur) or (s_a_falling and r_b_cur);
    s_cntclockwise <= (s_b_rising and not r_a_cur) or (s_b_falling and r_a_cur);

    -- Compteur
    cnt_dcnt : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_cnt <= (others => '0');
        elsif (rising_edge(i_clk)) then
            if (s_en = '1') then
                if (s_clockwise = '1') then
                    r_cnt <= r_cnt + 1;
                elsif (s_cntclockwise = '1') then
                    r_cnt <= r_cnt - 1;
                end if;
            end if;
        end if;
    end process cnt_dcnt;

    o_leds <= std_logic_vector(r_cnt);
end architecture rtl;
```

##### Simulation
Nous simulons le composant `encoder` dans le fichier `encoder_tb.vhd`. Le testbench génère les signaux A et B de l'encodeur, ainsi que l'horloge et le reset. Il vérifie ensuite que la valeur du compteur est correcte en fonction des rotations de l'encodeur.

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder_tb is
    generic (
        PERIOD_S_EN : natural := 10;
        WIDTH : natural := 10
    );
end entity encoder_tb;

architecture tb of encoder_tb is

    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz

    -- Signaux de test
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal A     : std_logic := '0';
    signal B     : std_logic := '0';
    signal leds  : std_logic_vector(WIDTH-1 downto 0);
    signal ended : boolean := false;

    constant DELAY : time := PERIOD_S_EN * CLK_PERIOD;

begin

    -- Instanciation du composant
    uut: entity work.encoder
        generic map (
            PERIOD_S_EN => PERIOD_S_EN,  
            WIDTH  => WIDTH
        )
        port map (
            i_clk   => clk,
            i_rst_n => rst_n,
            i_A     => A,
            i_B     => B,
            o_leds  => leds
        );

    -- Génération de l'horloge (50 MHz)

    stim_proc: process
    begin

        rst_n <= '0';
        A <= '0';
        B <= '0';
        wait for 10 * CLK_PERIOD;
        
        rst_n <= '1';
        wait for 10 * CLK_PERIOD;


        A <= '1'; wait for DELAY;
        B <= '1'; wait for DELAY;
        A <= '0'; wait for DELAY;
        B <= '0'; wait for DELAY;

        wait for DELAY * 4;

        B <= '1'; wait for DELAY;
        A <= '1'; wait for DELAY;
        B <= '0'; wait for DELAY;
        A <= '0'; wait for DELAY;

        wait for DELAY * 4;
        ended <= true;
        wait;
    end process stim_proc;

    clk_process: process
    begin
        clk <= '0';
        wait for (CLK_PERIOD/2);
        clk <= '1';
        wait for (CLK_PERIOD/2);
        if (ended = true) then
            wait;
        end if; 
    end process;

end architecture tb;
```

Dans le simulateur, nous faisons en sorte d'afficher tous les signaux d'entrée et de sortie du composant `encoder`. Nous pouvons ainsi vérifier que le compteur s'incrémente et se décrémente correctement en fonction des rotations de l'encodeur.

```vhdl
quit -sim

vlib work
vmap work work

vcom encoder.vhd
vcom encoder_tb.vhd

vsim work.encoder_tb

# INPUTS
add wave -divider inputs:
add wave -color yellow uut/i_clk
add wave -color yellow uut/i_rst_n
add wave -color yellow uut/i_A
add wave -color yellow uut/i_B

#ENCODER_VAR
add wave -divider Encoder_var:
add wave uut/s_en
add wave uut/r_a_cur
add wave uut/r_a_prev
add wave uut/r_b_cur
add wave uut/r_b_prev
add wave uut/s_a_rising
add wave uut/s_a_falling
add wave uut/s_b_rising
add wave uut/s_b_falling
add wave uut/s_clockwise
add wave uut/s_cntclockwise
add wave uut/r_cnt

#OUTPUTS
add wave -divider Outputs:  
add wave uut/o_leds

run -all
wave zoom full
```

![](img/encoder_tb.png)

##### Contrôleur HDMI
###### Ajoutez le fichier ```hdmi_controler.vhd``` au projet.
Nous ajoutons le fichier ```hdmi_controler.vhd``` au projet Quartus provenant du TD.

###### Instanciez le composant ```hdmi_controler``` dans votre fichier top (```telecran.vhd```).
Nous instancions le composant ```hdmi_controler``` dans le fichier top (```telecran.vhd```) en connectant les signaux d'horloge, de reset et de sortie HDMI.

```vhdl
	component hdmi_controler
		generic (
			h_res 	: positive := 720;
			v_res 	: positive := 480;
			h_sync	: positive := 61;
			h_fp	: positive := 58;
			h_bp	: positive := 18;
			v_sync	: positive := 5;
			v_fp	: positive := 30;
			v_bp	: positive := 9
		);
		port (
			i_clk  		: in std_logic;
			i_rst_n 	: in std_logic;
			o_hdmi_hs   : out std_logic;
			o_hdmi_vs   : out std_logic;
			o_hdmi_de   : out std_logic;
			o_pixel_en : out std_logic;
			o_pixel_address : out natural range 0 to (h_res * v_res - 1);
			o_x_counter : out natural range 0 to (h_res - 1);
			o_y_counter : out natural range 0 to (v_res - 1)
		);
	end component;
```

Puis nous connectons les signaux d'horloge et de reset, ainsi que les sorties du contrôleur HDMI aux signaux correspondants dans le top.

```vhdl
	-- Generates HDMI sync signals and pixel coordinates (480p)
	hdmi_controler0 : component hdmi_controler
		generic map (
			h_res => h_res,
			v_res => v_res
		)
		port map (
			i_clk => s_clk_27,
			i_rst_n => s_rst_n,
			o_hdmi_hs => o_hdmi_tx_hs,
			o_hdmi_vs => o_hdmi_tx_vs,
			o_hdmi_de => o_hdmi_tx_de,
			o_pixel_en => open,
			o_pixel_address => open,
			o_x_counter => s_x_counter,
			o_y_counter => s_y_counter
		);
```

###### Connectez les sorties pixel (signal ```o_hdmi_tx_d```) aux compteurs x, y.
Nous utilisons l'exemple de l'énoncé :
```vhdl
o_hdmi_tx_d(23 downto 16) <= std_logic_vector(to_unsigned(s_x_counter, 8));
o_hdmi_tx_d(15 downto 8) <= std_logic_vector(to_unsigned(s_y_counter, 8));
o_hdmi_tx_d(7 downto 0) <= (others => '0');
```

Nous obtenons alors :

![](img/hdmi_test1.png)

Nous testons ensuite avec un autre exemple :
```vhdl
o_hdmi_tx_d(23 downto 16) <= std_logic_vector(to_unsigned(s_x_counter, 8));
o_hdmi_tx_d(15 downto 8) <= (others => '0');
o_hdmi_tx_d(7 downto 0) <= std_logic_vector(to_unsigned(s_y_counter, 8));
```

![](img/hdmi_test2.png)

###### À quels bits correspondent chaque composante couleur ?
Grâce à ces tests, nous pouvons identifier les bits correspondant à chaque composante couleur.

Les bits de la sortie HDMI sont organisés comme suit :
* bits 23 à 16 : composante rouge
* bits 15 à 8 : composante verte
* bits 7 à 0 : composante bleue

### Déplacement d'un pixel
Cette étape consiste à afficher un seul pixel blanc sur fond noir, déplacé par les deux encodeurs :
* l'encodeur gauche déplace le pixel à l'horizontale (coordonnée x) ;
* l'encodeur droit déplace le pixel à la verticale (coordonnée y).

#### Principe
On réutilise le composant `encoder` de la partie précédente (copié dans `telecran/encoder.vhd` et ajouté au projet Quartus), instancié deux fois pour chaque encodeur. La valeur de chaque compteur donne directement la position du pixel.

Les encoders modifient `s_x_pixel` et `s_y_pixel`, qui sont comparés à `s_x_counter` et `s_y_counter` pour déterminer la couleur du pixel à afficher.
* blanc si `s_x_pixel = s_x_counter` et `s_y_pixel = s_y_counter` (`x"FFFFFF"`)
* noir sinon (`x"000000"`)

Les encodeurs sont cadencés par l'horloge HDMI à 27 MHz (`s_clk_27`) qui est différente de l'horloge à 50 MHz. Pour garder une période d'échantillonnage de 10 ms, `PERIOD_S_EN` est à 270000 (soit 10 ms).

#### Implémentation en VHDL
```vhdl
    -- 270000 @ 27 MHz = 10 ms
    constant enc_period : natural := 270000;
    constant enc_width : natural := 10;

	signal s_x_pixel : std_logic_vector(enc_width-1 downto 0);
	signal s_y_pixel : std_logic_vector(enc_width-1 downto 0);
begin
	-- Left encoder: horizontal position of the pixel
	encoder_left : component encoder
		generic map (
			PERIOD_S_EN => c_enc_period,
			WIDTH => c_enc_width
		)
		port map (
			i_clk => s_clk_27,
			i_rst_n => s_rst_n,
			i_A => i_left_ch_a,
			i_B => i_left_ch_b,
			o_leds => s_x_pixel
		);

	-- Right encoder: vertical position of the pixel
	encoder_right : component encoder
		generic map (
			PERIOD_S_EN => c_enc_period,
			WIDTH => c_enc_width
		)
		port map (
			i_clk => s_clk_27,
			i_rst_n => s_rst_n,
			i_A => i_right_ch_a,
			i_B => i_right_ch_b,
			o_leds => s_y_pixel
		);

	-- Pixel colors: white point with encoder
	o_hdmi_tx_d <=
		x"FFFFFF" when (to_integer(unsigned(s_x_pixel)) = s_x_counter and to_integer(unsigned(s_y_pixel)) = s_y_counter)
	    else x"000000";
```

![](img/pixel.gif)

### Mémorisation
#### Qu'est ce qu'une mémoire *dual-port* ?
Une mémoire "dual port" est une mémoire à laquelle on peut accéder  de deux manières indépendantes. Dans le projet, ce type de mémoire est utile pour faire des opérations simultanément pour écrire ou lire les données. Pour écrire les pixels dans la mémoire par les encodeurs et en même temps lire la mémoire pour récupérer l'état de chaque pixel et rafraîchir l'écran.
ici, on a besoin d'une mémoire dual-port car l'écran (en 27MHz) ne fonctionne pas à la même fréquence que le reste des composants. 

#### Schéma pour mémoiriser les pixels
![](img/mem_pixel.png)
#### Implémentation en VHDL
```vhdl
component dpram
		generic
		(
			mem_size    : natural := 720 * 480;
			data_width  : natural := 8
		);
		port
		(
			i_clk_a        : in std_logic;
			i_clk_b        : in std_logic;

			i_data_a    : in std_logic_vector(data_width-1 downto 0);
			i_data_b    : in std_logic_vector(data_width-1 downto 0);
			i_addr_a    : in natural range 0 to mem_size-1;
			i_addr_b    : in natural range 0 to mem_size-1;
			i_we_a      : in std_logic := '1';
			i_we_b      : in std_logic := '1';
			o_q_a       : out std_logic_vector(data_width-1 downto 0);
			o_q_b       : out std_logic_vector(data_width-1 downto 0)
		);
	end component;
```
On ajoute un process `cursor_address` pour avoir une coordonnées unique pour la RAM.
```vhdl
cursor_address : process(s_x_pixel, s_y_pixel)
		variable x : natural;
		variable y : natural;
	begin
		x := to_integer(unsigned(s_x_pixel));
		y := to_integer(unsigned(s_y_pixel));
		if (x < h_res) and (y < v_res) then
			s_cursor_address <= x + (y * h_res);
			s_cursor_valid <= '1';
		else
			s_cursor_address <= 0;
			s_cursor_valid <= '0';
		end if;
	end process cursor_address;
```
On ajoute un système de mémoire avec framebuffer, le port A va écrire Port A écrit 1 à l’adresse du stylet quand s_cursor_valid autorise l'écriture.
Port B lit l’adresse du pixel que le contrôleur HDMI est en train d’afficher.
``` vhdl
framebuffer : component dpram
		generic map (
			mem_size => h_res * v_res,
			data_width => 1
		)
		port map (
			i_clk_a => s_clk_27,
			i_clk_b => s_clk_27,
			i_data_a => "1",
			i_data_b => "0",
			i_addr_a => s_cursor_address,
			i_addr_b => s_pixel_address,
			i_we_a => s_cursor_valid,
			i_we_b => '0',
			o_q_a => open,
			o_q_b => s_ram_q_b
		);
```
On change alors l'output pour afficher le pixel blanc si le bit de la RAM est à 1, sinon on affiche noir.
``` vhdl
o_hdmi_tx_d <= x"FFFFFF" when s_ram_q_b(0) = '1' else x"000000";
```

![](img/framebuffer.gif)

### Effacement
Il faut parcourir toutes les adresses de la RAM pour y écrire un zéro. Pour cela nous utilisons un compteur qui va de 0 à l'adresse finale. Nous utilisons le signal `i_left_pb` pour déclencher l'effacement. Pour cela nous utilisons une machine à états. Quand le signal est à 0, nous mettons la machine dans l'état d'effacement, nous initialisons le compteur à 0 et nous commençons à écrire des zéros dans la RAM. Quand le compteur atteint la valeur maximale, nous arrêtons l'effacement et nous pouvons recommencer à dessiner en remettant le signal `o_clearing` à 0.

![](img/eraser.png)

#### Machine à états
La machine n'a que deux états, codés par le registre `r_clearing` :

| État | `r_clearing` | Ce qui se passe | Transition |
|---|---|---|---|
| Dessin | 0 | Le stylet écrit des 1 dans la RAM | Appui sur le bouton (`r_pb = 0`) → Effacement |
| Effacement | 1 | Le compteur avance de 1 à chaque cycle et écrit des 0 | `r_address = mem_size - 1` → Dessin |

Après un reset, la machine démarre dans l'état Effacement : l'écran est donc effacé à chaque démarrage. Un effacement complet dure 345 600 cycles, soit environ 12,8 ms à 27 MHz, ce qui est invisible à l'œil.

#### Implémentation en VHDL
Nous créons le composant `eraser` dans le fichier `eraser.vhd`. La taille de la mémoire est passée en `generic` pour pouvoir simuler avec une petite mémoire.

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity eraser is
    generic (
        mem_size : positive := 720 * 480
    );
    port (
        i_clk      : in std_logic;
        i_rst_n    : in std_logic;
        i_pb_n     : in std_logic;
        o_clearing : out std_logic;
        o_address  : out natural range 0 to mem_size - 1
    );
end entity eraser;

architecture rtl of eraser is
    signal r_pb : std_logic := '1';

    signal r_clearing : std_logic := '1';
    signal r_address  : natural range 0 to mem_size - 1 := 0;
begin
    push : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_pb <= '1';
        elsif rising_edge(i_clk) then
            r_pb <= i_pb_n;
        end if;
    end process push;

    -- Address counter
    counter : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_clearing <= '1';
            r_address  <= 0;
        elsif rising_edge(i_clk) then
            if (r_clearing = '1') then
                if (r_address = mem_size - 1) then
                    r_clearing <= '0';
                    r_address  <= 0;
                else
                    r_address <= r_address + 1;
                end if;
            elsif (r_pb = '0') then
                r_clearing <= '1';
            end if;
        end if;
    end process counter;

    o_clearing <= r_clearing;
    o_address  <= r_address;
end architecture rtl;
```

Le process `push` contient la bascule D du bouton. Le process `counter` contient la machine à états et le compteur d'adresses.

Nous instancions ensuite le composant dans `telecran.vhd` et nous ajoutons le multiplexeur devant le port A de la RAM. L'effaceur est prioritaire sur le stylet :

```vhdl
eraser0 : component eraser
    generic map (
        mem_size => h_res * v_res
    )
    port map (
        i_clk => s_clk_27,
        i_rst_n => s_rst_n,
        i_pb_n => i_left_pb,
        o_clearing => s_clearing,
        o_address => s_clear_address
    );

-- Port A of the framebuffer: the eraser has priority over the pen
s_ram_addr_a <= s_clear_address when s_clearing = '1' else s_cursor_address;
s_ram_data_a <= "0" when s_clearing = '1' else "1";
s_ram_we_a <= '1' when s_clearing = '1' else s_cursor_valid;
```

Nous avons donc deux modes d'écriture dans la RAM, selon l'état de la machine à états. Le tableau suivant résume les signaux connectés au port A de la RAM :s

| | `s_ram_addr_a` | `s_ram_data_a` | `s_ram_we_a` |
|---|---|---|---|
| Effacement (`s_clearing = '1'`) | `s_clear_address` | `"0"` | `'1'` |
| Dessin (`s_clearing = '0'`) | `s_cursor_address` | `"1"` | `s_cursor_valid` |

##### Simulation
Nous simulons le composant `eraser` dans le fichier `eraser_tb.vhd`. Pour que la simulation soit courte, nous utilisons une mémoire de 32 cases au lieu de 345 600.

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity eraser_tb is
end entity eraser_tb;

architecture tb of eraser_tb is
    constant MEM_SIZE   : positive := 32;    -- small RAM for short simulation
    constant CLK_PERIOD : time := 37 ns;     -- ~27 MHz

    signal clk           : std_logic := '0';
    signal rst_n         : std_logic := '0';
    signal pb_n          : std_logic := '1';
    signal clearing      : std_logic;
    signal clear_address : natural range 0 to MEM_SIZE - 1;
    signal ended         : boolean := false;
begin
    uut : entity work.eraser
        generic map (
            mem_size => MEM_SIZE
        )
        port map (
            i_clk      => clk,
            i_rst_n    => rst_n,
            i_pb_n     => pb_n,
            o_clearing => clearing,
            o_address  => clear_address
        );

    stim_proc : process
    begin
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        rst_n <= '1';
        wait for 50 * CLK_PERIOD;

        pb_n <= '0';
        wait for 4 * CLK_PERIOD;
        pb_n <= '1';
        wait for 50 * CLK_PERIOD;

        ended <= true;
        wait;
    end process stim_proc;

    clk_process : process
    begin
        clk <= '0';
        wait for (CLK_PERIOD / 2);
        clk <= '1';
        wait for (CLK_PERIOD / 2);
        if (ended = true) then
            wait;
        end if;
    end process clk_process;
end architecture tb;
```

Nous utilisons le script `eraser.do` pour lancer la simulation dans ModelSim :

```tcl
quit -sim

vlib work
vmap work work

vcom eraser.vhd
vcom eraser_tb.vhd

vsim work.eraser_tb

# INPUTS
add wave -divider inputs:
add wave -color yellow uut/i_clk
add wave -color yellow uut/i_rst_n
add wave -color yellow uut/i_pb_n

# ERASER
add wave -divider eraser:
add wave uut/r_pb
add wave uut/r_clearing
add wave -radix unsigned uut/r_address

# OUTPUTS
add wave -divider outputs:
add wave uut/o_clearing
add wave -radix unsigned uut/o_address

run -all
wave zoom full
```
