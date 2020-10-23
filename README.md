# Cats-and-Mices
The basis of this project is the creation of intelligent agents capable of perceiving and responding to different behaviors simultaneously, relating to the environment in which they are inserted.
In the first phase of the project, we implemented the rational behavior of agents, increasing their ability to react to events in the environment.
In the second phase of the project, we increased the level of understanding of the agents, here they are able to reproduce, form litters, feed and even attack other rats, since cannibalism is very common in rats.

This project was developed within the scope of the course IIntrodução à Inteligência Artificial @ Instituto Superior de Engenharia de Coimbra.

## Usage
In order to run this project you must use Netlogo 6.1.1
To download Netlogo use the following [link](https://ccl.northwestern.edu/netlogo/)

## TODO
### Racional Behavior
##### Mice
- [ ] If perceive a cat in 8 neighbors => Run away 2 patches
- [ ] If a lonely mouse perceive other lonely => Do nothing!
- [ ] If a lonely mouse perceive a litter/friendly => ATACK!
- [ ] If a friendly mouse perceive a litter => Join them!

##### Cats
- [ ] If a mouse is 2 patches in front of them, he could run to them => kill any mice

### Generalization of the model
- [ ] Poisoned Food
- [ ] Reproduction
    - Start small and grow up
- [ ] Friendly and Lonely mice
    - Create a litter if 15 or more mice are in the same 8 neighborhood
- [ ] Poison cat when he eat a poisoned mouse
