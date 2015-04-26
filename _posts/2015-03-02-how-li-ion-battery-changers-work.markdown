---
permalink: "how-li-ion-battery-changers-work"
tags:
  - "charger"
  - "ideal diode"
  - "li-ion"
  - "li-poly"
  - "load prioritization"
  - "pmic"
  - "power path"
---
In this post we will see how the charging process works for Li-ion batteries and how to choose the appropriate PMIC (Power Management Integrated Circuit) charger. What described below applies also to Li-poly cells.

## How to charge a Li-ion battery

### Charging parameters

The Li-ion batteries cannot be charged by simply connecting them to a voltage source: this will most probably damage them irremediably or even make them explode. Families of PMIC have been specifically designed to protect them during their charging phases. There are essentially two constraints that must be constantly enforced:

* __The maximum current \\(I_{max}\\).__ Every battery datasheet reports the suggested maximum charging current. As a rule of thumb you can estimate this parameter by dividing the battery capacity by 2h. Example: if you are dealing with a 300mAh accumulator, a good guess for its $I_{max}$ is 150mA. Some producers provide also a &laquo;fast charging current&raquo; that is usually set to twice the &laquo;standard&raquo; value. Using a smaller value will lead to a longer charging time, but at the end the battery will reach a 100% charge. Exceeding the recommended value will damage or destroy the cell.
* __The maximum voltage $V_{max}$.__ This is the maximum potential difference across the two battery terminals. Also in this case you should find the correct value in the datasheet or printed on the component body. This parameter depends strongly on the two chemical elements that constitute the accumulator. For Li-ion it is almost always around 4.2V. Configuring a smaller value will not slow down the charge, but it will interrupt it prematurely, preventing the accumulator to reach the 100% level. Going beyond the correct value will cause malfunctions or the death of the battery.

Below you find the block diagram of a generic charger IC.

![](/images/charger-block-diagram.svg)

The main building blocks are:

* __A regulator.__ It can operate in linear or switched mode. More details on this element are described in the sections below. Its goal is to reduce the input voltage $U_{in}$ to $U_{out}$. The ratio is imposed by the controller.
* __A current sensor.__ Constantly compares the output current with the threshold $I_{max}$.
* __A voltage sensor.__ It's not needed to know the exact output voltage value, but only if the level reached can be dangerous for the battery. It is realized with a comparator and a reference voltage source set to the $V_{max}$.
* __A controller.__ It receives the feedbacks from the voltage comparator and the current sensor (dashed lines) and adapts the regulator operating point accordingly.

### Dangers

As all the types of batteries, li-ion do self-discharge with time. When the battery level is really low, its voltage could drop to levels near 1.5V. In this case there is the danger that some shorts could form in the cell, so you always have to check the accumulator tension with a voltmeter before recharging or you have to read the datasheet of the PMIC you are using to ensure that this check is integrated in the chip logic. Nowadays most batteries have an internal protection that irreversibly breaks the cell connections to the outside when the voltage drops below 2.7V.

### Charging phases

Also if the controller operates continuously and linearly, we can observe at least two distinct phases that characterize also the name of the chargers: CI+CV, i.e. constant current and constant voltage. Each producer adopts its own strategy variations: I will try to describe the steps without binding too much on a specific manufacturer implementation choices. The plot below is a simplified trace of the process:

![](/images/li-ion-charging-phases.svg)

* __Trickle charging.__ If the battery level is considered very low (below 2.8V), it is charged with a current that is usually an order of magnitude lower than $I_{max}$. If the battery voltage doesn't go above 2.8V for a preconfigured amount of time, the charger halts.
* __Constant current.__ This behavior can be observed when the battery voltage is below its $V_{max}$, but above the safety guard level of 2.8V. The controller operates the regulator so that a constant current $I_{max}$ is fed into the battery. It corresponds to the part of the plot to the left of the dashed line. In the example $I_{max}$ is set to 100mA. In reality the cell voltage doesn't increase linearly, but follows a very irregular trend.
* __Constant voltage.__ This is the second phase of the charging process, depicted in the right portion of the plot. The current is reduced so that the battery voltage doesn't exceed $V_{max}$ (that in the plot is set to 4.2V). The current decreases slowing down the progress. The charge terminates when the current drops to a preconfigured fraction of $I_{max}$.
* __Trickle charging.__ Some manufacturers introduce another trickle charging phase here to maintain an high charge level.

## Types of chargers

There are essentially two ways of implementing the regulator shown in the block diagram: with a linear component or using the switching technology. In the following sections we will see how they compare.

### Linear

The linear component here is normally a MOSFET. The big advantage is that the component count is reduced to a single element or, for small applications, it can even be integrated in the same chip. The RF interferences are also kept to a minimum, since there is no high frequency activity in this type of regulator. Of course the main drawback is the low efficiency caused by the power dissipation that is equal to:

$$
P = I_{in} V_{in} - I_{out} V_{out}
$$

since, for a linear regulator, the input and output current are the same:

$$
P = I_{out} \left(V_{in} - V_{out} \right)
$$

Many regulators have special packages that have extra pads on the bottom side to ensure a proper thermal dissipation. This sometimes creates some difficulties to the hobbyist that is used to the classic soldering iron, as those pin are not directly accessible. Using an heat gun not always solves the problem because the hot air fails to reach the paste between the component and the board. As if that is not enough, when the paste melts, the component will sit on the board, preventing us from inspecting the soldering quality. An insufficient power dissipation will cause the death of the chip or, if it has some sort of protection, a longer charging time.

Another side effect of a reduced efficiency is particularly evident when the supply isn't provided by a wall adapter, but with a limited power connection as an USB host/hub. In fact, for batteries with capacities higher than 1Ah, the constant-current phase of the charge will be slowed down by the limits imposed by the standard, i.e. $I_{max}$=500mA (because $I_{in} = I_{out}$). 

### Switching

Switching regulators rely on an alternating scheme of charge and discharge of reactive components, usually inductors. In the first phase the coil is powered with the available power source, so that a magnetic field is created. In the second, the energy stored is reversed on the output (in our case, the battery). Varying the duration of the two steps, one can achieve different ratios of input/output voltages. The output current is not necessarily equal to the input current, but the relation is:

$$
V_{out} I_{out} \leq \eta V_{in} I_{in}
$$

where $\eta$ is the regulator efficiency.
This solution requires more external components and this rises the costs and size of the board. The circuit must also be appropriately shielded to avoid releasing too many EMI or it must use components specifically made for this purpose. On the other side, no big heatsinks are usually required. 

These configurations reach levels of efficiency as high as 95%. A speedup in the charging process is evident when the supply has limited power and the battery level is very low. For example if the charger is USB powered and the battery has $U$=3V, with a linear regulator the current will be limited to that available from the USB connection (500mA),instead with a switching charger with an efficiency of 90%, it could reach:

$$
I_{out} = \eta \frac{V_{in}}{V_{out}} I_{in} = 0.9 \cdot \frac{5V}{3V} \cdot 500mA = 750mA
$$

The increase of the maximum available current from 500mA to 750mA reduces the constant current phase duration by 33%.

## Charging during utilization

Often we don't want to disconnect the battery from the appliance it is powering to charge it. This eliminates the need of a spare accumulator and the downtime for the substitution. For example mobile phones continue to operate seamlessly when the USB cable is plugged in. You could be tempted to use a scheme like the one below: 

![](/images/charger-wrong-wiring.svg)

Why is the drawing crossed out? Well, for two good reasons:

1. The current going out the charger must now feed both the battery and the load (represented by $R_{load}$). This means that the current sensor embedded in the regulator cannot measure precisely the current that goes into the cell. The effect is a longer charging time because the load &laquo;steals&raquo; part of the current meant to flow in the battery. If the cell has $I_{max}$ = 100mA and the load requires 80mA, only 20mA will be delivered to the cell, increasing the constant current phase duration by 400%.
2. The voltage on the cell equals that on the load. This means that when the battery is heavily discharged, the load supply could be as low as 2.8V. If you are dealing with a logic circuit that needs for example 3.3V to work, you will have to wait until the battery reaches that level to be able to use it.

In the following subsections we will see a couple of tricks to mitigate the two problems listed above.

### Mosfet and diode trick

This is a simple schematic that uses a MOSFET, a Schottky diode and a couple of capacitors to automatically switch the power source between the battery and an external source like a wall adapter. Sometimes the two active components are placed in the same package. This solution works only if the current available from the external power source is always at least the sum of the maximum battery charge current $I_{max}$ and the maximum load current. 

* __Autonomous operation.__ $R_{pull}$ pulls $U_{in}$ low so that $Q_1$ conduction connects the battery to the load (depicted by $R_{load}$). $D_1$ is inversely polarized, so it's not conductive.
* __External power source connected.__ When the wall adapter is attached to $U_{in}$, $Q_1$ will isolate the battery from the load, so that the regulator will power only the cell. The load will be powered through $D_1$. A Schottky diode has been chosen to reduce as much as possible the voltage drop.

![](/images/charging-diode-mosfet.svg)

### Ideal diode

Many manufacturers have created a more advanced version of what explained in the previous subsection. Each one adopted its own naming for this technology, but essentially what their solutions achieve is the same. Other than being able to attach and remove an external power source without disrupting the load operation, is also possible to:

* Set a limit on the incoming current. This is needed if the external energy source must satisfy some standard criteria. For example, all the devices attached to the USB network are required to sink at most 500mA. This poses the problem of how to balance the current on the load and on the battery. The solution in called &laquo;load prioritization&raquo;: the load gets all the current it needs (but almost 500mA) and if it requires less than 500mA, the remaining amount can be used to charge the accumulator.
* Combine the battery and the external source to deliver more current to the load. Going back to the USB example, when the load asks for 600mA, the bus can provide the first 500mA and the remaining 100mA could be drawn from the battery (if possible). This scheme is often called &laquo;ideal diode&raquo; because this cooperation between the two power sources could be theoretically realized using two ideal diodes (i.e. that have no voltage drop when forward polarized).

## Conclusion

If you want to find the correct PMIC for your project I suggest you to give a look at the Linear Technology website that has a dedicated section and a simple tool to select the products that match your specs. Despite the company name, they provide both linear and switching chargers. Their datasheet are well-organized and, after reading this post, I hope you will find yourself comfortable with the terms and concepts they contain.
