/**
* Name: FSMmodel
* Based on the foraging and size model. Includes memory. A population dynamics model in a heterogeneous landscape with four types of fruit trees where seasonality can be simultaneous or sequential.

* Author: newma
* Tags: 
*/


model FSMmodel

/* Insert your model definition here */

global torus: true {
	
	file grid_map <- file("C:/Users/newma/gama_workspace/Foraging_model_with_size/includes/single_fruit_5p.asc");
	file proba_stay_tree <- csv_file("../includes/proba_of_staying_tree.csv", ","); 
	//file grid_map;  // generic when multiple maps are utilised in the experiments
	geometry shape <- envelope(grid_map);
	string map_name;
 	date starting_date <- date(2020, 8, 24);
 	int nb_fly <- 5;
 	int max_flies <- 0;
 	int nb_adult_total <- 0;
	float step <- 1 #day;
	float speed <- 1.0;
	bool memory;
	bool simultaneous_season <- false;
 
 	// Cohort parameters
 	float egg_mortality;
	//float larval_mortality; // TODO  set to nothing for multiple simulations. These values are set within the cohort entity
	//float pupal_mortality;
	//int days_in_L_stage;
	//int days_in_P_stage;
	
	// Fly parameters
	int mature_age <- 10;
	float days_in_IM_stage;
	int daily_flies;
 	int nb_adults <- 0;
	int nb_cohort;
	float mortality_chance;
	float wing_length ; //TODO set to nothing for multiple runs
	int days_in_non_host;
	int days_in_poor_host;
	int days_in_ave_host;
	int days_in_good_host;
	list<tree> host_trees <- tree where (each.grid_value >= 1);
	int immature_flies_over_time;
	int total_all_fly_fecundity;
	int host_good_emergence;
	int host_average_emergence;
	int host_poor_emergence;
	float step_distance;
	float pf_larval_tolerance <- 10.0; // Percent of occupancy/larval_density that the fly will tolerate
	
	// the parameters of the weibul function for daily fecundity
 	float beta; 
 	float enya; 
 	float loc;
	float coeff; 
	
 	// parameters for the calculation of the survival curve
 	float xmid;
	float L;
	float E; 
	
	//	 memory affiliation probability to stay
 	matrix proba_stay <- matrix(proba_stay_tree);
	list memory_prob_1 <- proba_stay column_at 1;
	list memory_prob_2 <- proba_stay column_at 2;
	list memory_prob_3 <- proba_stay column_at 3;
	list memory_prob_4 <- proba_stay column_at 4; 
	
	// 	Tree parameters
 	// 	parameters for calculating number of fruit per tree over time	
 	float a <- 10.0;  // height of curve
 	float b <- 80.0; // centre of the peak
 	float c <- 30.0; // the width of the bell curve
 	int max_larvae_per_fruit <- 5; 	//TODO remove value for experiments
// 	list<tree> trees_with_fruits <- tree where(each.num_fruit_on_tree >=1) update: tree where(each.num_fruit_on_tree >=1);
 	 
 	 
 	//REFLEXES
 	
 	reflex count_max {
 		if max_flies < nb_adults {
				max_flies <- nb_adults;
			}
 	}
 	
 	reflex flies_over_time {
		daily_flies <- length(fly);
		//immature_flies_over_time <- fly count (each.state = "immature_adult");
		total_all_fly_fecundity <- fly sum_of (each.cumulative_fecundity);
		//host_good_emergence <- length(fly where (each.my_larval_host = "good"));
		//host_good_emergence <- fly count (each.my_larval_host = "good");
		//host_average_emergence <- length(fly where (each.my_larval_host = "average"));
		//host_average_emergence <- fly count (each.my_larval_host = "average");
		//host_poor_emergence <- length(fly where (each.my_larval_host = "poor"));
		//host_poor_emergence <- fly count (each.my_larval_host = "poor");
	}

	int total_fruit -> tree sum_of(each.num_fruit_on_tree);
	int flies_in_non_host -> tree where (each.fruit_quality = "non") sum_of (each.nb_flies_inside_tree);
//	int flies_in_poor_host -> tree where (each.fruit_quality = "poor") sum_of (each.nb_flies_inside_tree);
//	int flies_in_average_host -> tree where (each.fruit_quality = "average") sum_of (each.nb_flies_inside_tree);
	int flies_in_good_host -> tree where (each.fruit_quality = "good") sum_of (each.nb_flies_inside_tree); //// This code is for saving time step values during the batch runs
	int total_good_fruit -> tree where (each.fruit_quality = "good") sum_of (each.num_fruit_on_tree);
// 	int total_poor_fruit -> tree where (each.fruit_quality = "poor") sum_of (each.num_fruit_on_tree);
// 	int total_average_fruit -> tree where (each.fruit_quality = "average") sum_of (each.num_fruit_on_tree);
// 	int total_lf_fecundity_poor <- fly where(each.my_larval_host = "poor") sum_of (each.cumulative_fecundity);
// 	int total_lf_fecundity_average <- fly where(each.my_larval_host = "average") sum_of (each.cumulative_fecundity);
 	int total_lf_fecundity_good <- fly where(each.my_larval_host = "good") sum_of (each.cumulative_fecundity);
 	
 	reflex stop_sim when: cycle = 1825 {
 		do pause;
 		do die;
	}
 	
 	// Save code at each time step (from .csv file)
 	reflex save {
		save 
		[
		"simulation" + (int(self)), 
		cycle, 
		// simultaneous_season, map_name, 
		nb_adult_total, 
		max_flies, 
		total_fruit, 
		//total_good_fruit, total_poor_fruit, total_average_fruit,
		flies_in_good_host, 
		//flies_in_average_host, 
		//flies_in_non_host, 
		//flies_in_poor_host, 
		//flies_in_good_host,
		//days_in_ave_host, 
		days_in_non_host, //days_in_poor_host, 
		days_in_good_host,
		current_date, 
		daily_flies, 
		total_all_fly_fecundity,
		max_larvae_per_fruit
		//wing_length, 
		//larval_mortality, 
		//pupal_mortality,
		//days_in_L_stage,
		//days_in_P_stage
		//host_good_emergence, host_average_emergence, host_poor_emergence,
		//total_lf_fecundity_poor, total_lf_fecundity_average, total_lf_fecundity_good, 
		]
		to: "../data/results/global.csv" type: "csv" header: true rewrite: false;
 	}
 	
// 	reflex save_map {
// 		save tree to: "../data/results/map" + map_name + "map.png" type: "image";
// 		save fly to: "../data/results/map" + map_name + "fly.png" type: "image";
// 	}

	reflex cycles { 
 		write 
 		 " cycle: " + cycle	+ " " + int(self) 
 		+ " number of flies: " + daily_flies;
 	}
	
 	init {create fly number: nb_fly {
 		    location <- any_location_in(one_of(host_trees));
 		    myTree <- tree closest_to self;
			nb_adults <- nb_adults + 1;
			nb_adult_total <- nb_adult_total + 1;
			age <- 10.0;
			adult_age <- 10.0;
			my_cohort <- "start";
			my_larval_host <- myTree.fruit_quality;
			}
		}
	}

species fly skills: [moving] control: fsm {
	tree myTree <- one_of(tree);  // name of tree
	string current_tree_quality;
 	string my_cohort;
 	string my_larval_host;
 	float my_larval_mortality_chance;
 	float my_pupal_mortality_chance;
 	int my_larval_development_time;
 	int my_pupal_development_time;
	int daily_fecundity;
	int cumulative_fecundity;
	float age; 
 	float adult_age;
	float mortality_chance;
	float prob_lay_eggs;
	int counter <- 0;
	int memory_count;
	string current_affiliated_fruit;
	float wing_length; // TODO undo for experiments 
	float sensing_boundary <- 10#m;
	float step_distance;
	float searching_boundary;
	float cumulative_distance;
	float imm_cumulative_distance;
	
	/* LISTS for evaluating foraging
	 */
	list<tree> fruiting_trees; // where the trees are fruiting	
	list<tree> distant_fruiting_trees; //where trees are fruiting within thier searching boundary
 	list<tree> affiliated_fruit_within_boundary;  // Memory component
 	
 	/* Calculating the functions for 
 	 * distance, survival, mortality, and daily eggs
 	 * These functions are evaluated when called in the model
 	 */
 	float compute_distance_function {return (-2.7+2.7*(wing_length*0.35))*sensing_boundary;}
 	float compute_survival_curve {return L / (1 + (exp(E * (adult_age - xmid))));}
	float compute_mortality_chance (float survival_curve) {return (100 - survival_curve) / 100;}
	float compute_enya {return ((0.6411*wing_length^2)-(5.0078*wing_length)+35.293);}
	float compute_coeff {return ((200*enya) - 4600);}
	float compute_daily_eggs {return (round((beta / enya) * (((adult_age - loc) / enya) ^ (beta - 1)) * (exp(-(((adult_age - loc) / enya) ^ beta))) * (coeff)));}	
 	float compute_sd_of_eggs {return (0.1 * daily_fecundity);} 
 
 	// STATES 
	state immature_adult initial: true {
		enter {
			ask tree overlapping self {
				myself.myTree <- self;  // the name of the tree that it is on
			}
		if my_larval_host = "poor" {
 		wing_length <- gauss(5, 0.25);
 			}
 		if my_larval_host = "average " {
 		wing_length <- gauss(5.5, 0.25);
 			}
 		if my_larval_host = "good" {
 		wing_length <- gauss(6, 0.25);
 			}
 		searching_boundary <- compute_distance_function();	// The distance function requires wing length to evaluate
		}
		
		adult_age <- adult_age + (step/86400);
		do update_tree_quality;
		imm_cumulative_distance <- cumulative_distance;
		do simple_wander;
		daily_fecundity <- 0; 

		transition to: adult when: adult_age >= mature_age;
	}

	state adult {		
		adult_age <- adult_age + (step/86400);
		do update_tree_quality;
		if my_larval_host = "average" {
 	 		xmid <- 118.5;
			L <- 98.0; 
			E <- 0.04; 
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
		}
		
		if my_larval_host = "poor" {
 	 		xmid <- 100.0; 
			L <- 96.0;  // fixed at poor
			E <- 0.035; // fixed at poor
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
		}
		
		if my_larval_host = "good" {
 	 		xmid <- 137.0;
			L <- 100.0;  
			E <- 0.045; 
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
		}
		
		// The only action for movement. Contains directed and simple wander.
		do directed_move;
		
		// Daily Fecundity depending on larval host
		if adult_age > 7.0 {
			if my_larval_host = "poor" { 
 				beta <- 1.7;
 				loc <- 6.0;
				enya <- compute_enya();
				coeff <- compute_coeff();
				int daily_fecundity_result <- round(compute_daily_eggs());
				int daily_sd_fecundity_result <- round(compute_sd_of_eggs());
				daily_fecundity <- round(gauss(daily_fecundity_result, daily_sd_fecundity_result));
				}

			if my_larval_host = "average" { 
 				beta <- 1.7;
 				loc <- 6.0;
				enya <- compute_enya();
				coeff <- compute_coeff();
				int daily_fecundity_result <- round(compute_daily_eggs());
				int daily_sd_fecundity_result <- round(compute_sd_of_eggs());
				daily_fecundity <- round(gauss(daily_fecundity_result, daily_sd_fecundity_result));
				}

			if my_larval_host = "good" {
 				beta <- 1.7;
 				loc <- 6.0;
				enya <- compute_enya();
				coeff <- compute_coeff();
				int daily_fecundity_result <- round(compute_daily_eggs());
				int daily_sd_fecundity_result <- round(compute_sd_of_eggs());
				daily_fecundity <- round(gauss(daily_fecundity_result, daily_sd_fecundity_result));	
				}		
			
			if daily_fecundity < 0 or myTree.num_fruit_on_tree < 1 {
			// there can be a chance that the sd makes the daily fecundity a negative value, so if less than 0, it will default to 0.
 			daily_fecundity <- 0;
			} 			
		}

		// final action to perform as it determines the probability of the flies laying eggs.
		do probability_to_lay_eggs_in_tree; 
		do calculate_days_in_hosts;
		
		// update cumulative fecundity
		cumulative_fecundity <- cumulative_fecundity + daily_fecundity;
		transition to: overwintering_adult when: current_date between (date(current_date.year, 4, 14), date(current_date.year, 8,24));
	}

	state overwintering_adult {
		adult_age <- adult_age; // pauses the adult age at this age (adult_age is built into the fecundity function)
 		mortality_chance <- 0.0114;
		daily_fecundity <- 0;
		transition to: adult when: current_date = date(current_date.year, 8, 24);
	}
	
	// REFLEXES
	
	/* DIE
	 */
	reflex chance_to_die when: (flip(mortality_chance)) {
		nb_adults <- nb_adults - 1;
		save (string(cycle) + 
		"," + host + 
		"," + my_larval_host +
		"," + wing_length +
		"," + age + 
		"," + cumulative_fecundity + 
		"," + searching_boundary + 
		"," + imm_cumulative_distance +
		"," + cumulative_distance)
		to: "../data/results/ffas_good.csv" type: "csv" header:true rewrite: false;
		do die; 
	}
	
	/* Update age
	 */
	reflex update_age {
 		age <- age + 1;
 	}
 	
 	/* Update my tree quality
 	 */
	// ACTIONS //
	action update_tree_quality {
 	 	current_tree_quality <- myTree.fruit_quality;
 	 }
	/* Movement
	 */
	action simple_wander {
		do wander speed: searching_boundary #m / #s bounds: circle(searching_boundary, location); // speed: 1.0 #m / #day // this is the speed that they can move in a day
		location <- any_location_in(circle(searching_boundary, location));
		step_distance <- myTree distance_to(location);
		cumulative_distance <- cumulative_distance + step_distance;
		ask tree overlapping self {
				myself.myTree <- self;
				}
 		} 	
 		
 	/*  Directed move is based on OPTIMAL FORAGING / BEST CHOICE BEHAVIOUR. 
	 * The highest grid value within the sensing boundary is selected
	 */	
	action directed_move {
 			fruiting_trees <- (tree where (each.num_fruit_on_tree >= 1)) at_distance searching_boundary;	
 			distant_fruiting_trees <- (tree where (each.num_fruit_on_tree >= 1)) at_distance searching_boundary;
			if !empty(fruiting_trees) {
				do move speed: sensing_boundary #m / #s bounds: circle(sensing_boundary, location);
			    tree maxtree <- fruiting_trees with_max_of (each.grid_value);
			    float maxquality <- maxtree.grid_value; 
				tree bestTree <- shuffle(fruiting_trees) first_with (each.grid_value = maxquality);
				location <- bestTree.location;
				step_distance <- myTree distance_to(location);
				cumulative_distance <- cumulative_distance + step_distance;
				myTree <- bestTree;
				} 
			if empty(fruiting_trees) and !empty(distant_fruiting_trees) {
				do move speed: searching_boundary #m / #s bounds: circle(searching_boundary, location);
			    tree maxtree <- fruiting_trees with_max_of (each.grid_value);
			    float maxquality <- maxtree.grid_value; 
				tree bestTree <- shuffle(maxtree) first_with (each.grid_value = maxquality);
				location <- bestTree.location;
				step_distance <- myTree distance_to(location);
				cumulative_distance <- cumulative_distance + step_distance;
				myTree <- bestTree;
				} 
			if empty(fruiting_trees) and empty(distant_fruiting_trees) {
					do simple_wander;
				}
		}
		
		action move_to_affiliated {
		ask tree overlapping self {
			myself.myTree <- self;
		}
		fruiting_trees <- tree at_distance sensing_boundary where (each.num_fruit_on_tree >= 1);
		affiliated_fruit_within_boundary <- fruiting_trees where (each.fruit_quality = current_affiliated_fruit);
		if !empty(affiliated_fruit_within_boundary) {
			myTree <- one_of(fruiting_trees);
			location <- myTree.location;
		} else {
			do directed_move;
		}
	}
	
	action probability_to_stay {
//		if memory = true and current_tree_quality = "non" {
//			if (flip(0.05)) {
//				//do move_to_affiliated;
//			//} else {
//				do directed_move;
//				memory_count <- memory_count - 1;
//			}
//		}
		if memory = true and current_affiliated_fruit = "poor" {
			float my_exp_1 <- memory_prob_1 at counter;
			if (flip(my_exp_1)) {
				do move_to_affiliated;
				memory_count <- 3;
				counter <- 1;
			} else {
				do directed_move;
				memory_count <- memory_count - 1;
				counter <- counter + 1;
				if counter > 4 {
					counter <- 5;
				}
			}
		}
		if memory = true and current_affiliated_fruit = "average" {
			float my_exp_2 <- memory_prob_2 at counter;
			if (flip(my_exp_2)) {
				do move_to_affiliated;
				memory_count <- 3;
				counter <- 1;
			} else {
				do directed_move;
				memory_count <- memory_count - 1;
				counter <- counter + 1;
				if counter > 4 {
					counter <- 5;
				}
			}
		}
		if memory = true and current_affiliated_fruit = "good" {
			float my_exp_3 <- memory_prob_3 at counter;
			if (flip(my_exp_3)) {
 			do move_to_affiliated;
				memory_count <- 4;
				counter <- 1;
			} else {
				do directed_move;
				memory_count <- memory_count - 1;
				counter <- counter + 1;
				if counter > 4 {
					counter <- 5;
				}
			}
		} else {
			do directed_move;
		}
	}
 
    /* Probability that the female will lay in the tree depending on the percent capacity of cumulative eggs over time.
     */
		action probability_to_lay_eggs_in_tree {
		if myTree.num_fruit_on_tree > 0 and current_tree_quality = "non" or 
				(current_tree_quality = "poor" and myTree.percent_occupancy > pf_larval_tolerance) {
					prob_lay_eggs <- 0.0;
					daily_fecundity <- 0;
				}
		
		if myTree.num_fruit_on_tree > 0 and current_tree_quality = "average" {
			prob_lay_eggs <- (100 - myTree.percent_occupancy)/100;
			if !(flip(prob_lay_eggs)) {
				daily_fecundity <- 0;
				}
			}
			
			else {
				if myTree.num_fruit_on_tree > 0 and current_tree_quality = "good" {
				prob_lay_eggs <- 1.0;
				}
			}
		}
	
	/* Calculate the days spent in each host if not overwintering
 	  */
 	 action calculate_days_in_hosts {
 	 	if current_tree_quality = "non" {
 	 		days_in_non_host <- days_in_non_host + 1;
 	 	}
 	 	if current_tree_quality = "poor" {
 	 		days_in_poor_host <- days_in_poor_host + 1;
 	 	}
 	 	if current_tree_quality = "average" {
 	 		days_in_ave_host <- days_in_ave_host + 1;
 	 	}
 	 	if current_tree_quality = "good" {
 	 		days_in_good_host <- days_in_good_host + 1;
 	 	} 	 	
 	 }	

	/* Fly agent aesthetics
	 */
	aspect default {
		draw circle(searching_boundary) color: #pink empty: true;
		draw circle(sensing_boundary) color: #red empty: true;
		draw circle(0.3) color: #red;
	}
}

grid tree file: grid_map use_regular_agents: false {
	float grid_value <- grid_value;
	string fruit_quality;
	float season_day;
	//float days_since_harvest;
	int nb_cohorts_inside;
	int eggs_in_tree;
	int nb_eggs_in_tree;
	int nb_larvae_in_tree;
	int nb_pupae_in_tree;
	int nb_teneral_in_tree;
	int nb_flies_inside_tree;
	int capacity;
	int max_capacity <- 1;
	int emerged;
	int num_fruit_on_tree;
	int occupancy;
	float percent_occupancy;
	float percent_overcapacity; 
	bool in_season <- false;
	int rot;
	
	init {
		if grid_value = 0.0 {
			fruit_quality <- "non";
			color <- #white;
		}
		if grid_value = 1.0 {
			fruit_quality <- "good";  // TODO change back to poor
			color <- #salmon;
//			max_larvae_per_fruit <- 20; // TODO change back to 5
		}
		if grid_value = 2.0 {
			fruit_quality <- "good";
			color <- #gold;
//			max_larvae_per_fruit <- 10;
		}
		if grid_value = 3.0 {
			fruit_quality <- "good";
			color <- #lightgreen;
//			max_larvae_per_fruit <- 20;
		}
	}
 
 	/* SEASONS
 	 */  
 	 action reset_season {
			in_season <- false;
			season_day <- 0.0;
			occupancy <- 0;
			percent_occupancy <- 0.0;
			percent_overcapacity <- 0.0;
			emerged <- 0;
			max_capacity <- 1;
			rot <- 0;
		}
	
	action start_season {
			season_day <- season_day + (step/86400);
			num_fruit_on_tree <- round(a * exp(-((season_day - b) ^ 2) / (2 * (c ^ 2))));
			list<int> fruit_list <- num_fruit_on_tree;
		}
	
//	reflex reduce_fruit { // if comparing simultaneous and sequential fruiting and want to compare the same number of fruits.
//		if simultaneous_season = true {
//			a <- (a/2);
//		}
//	}

// MATRIX
/* Create a matrice for each fruit. 
 * The first column will be as the fruit becomes available, 
 * the second column is total eggs for all the flies in the tree and 
 * the third column is the number of flies
 * I want to iterate through the list of fruit and add 5 eggs to each until total eggs = 0
 */
	reflex fruit_egg_matrices {
		if num_fruit_on_tree > 0 {
		
		//list<int> flies_with_eggs <- fly where (each.myTree = self) sum_of (each.daily_fecundity);
		//int flies_inside <- fly count (each.myTree = self);
		//matrix<matrix> matrix_of_fruit <- matrix<matrix>({1,5} matrix_with matrix([[got_fruit],[flies_with_eggs], [flies_inside]])) ;
	    //matrix<int> got_fruit_matrix <- got_fruit as_matrix {length(num_fruit_on_tree), length(flies_with_eggs)}; 
	    //write matrix_of_fruit;
	    //int test <- length(got_fruit);
	    
	    
//	    loop i from: 1 to: num_fruit_on_tree {
//					if eggs_in_tree > 5 {
//						got_fruit <- got_fruit + 5;						
//						}
//					}

	    write got_fruit;
	    }
	}
	
	reflex limit_to_extended_emergence {
		if season_day > b and num_fruit_on_tree < 1 {
			rot <- rot + 1;
			}
		}
			
 	reflex poor_tree_fruiting when: fruit_quality = "good" { // TODO change back to poor
		if (
			((simultaneous_season = true) and (current_date = date(current_date.year, 1,5) or current_date = date(current_date.year, 8,25))) 
			or
			((simultaneous_season = false) and (current_date = date(current_date.year, 8,25)))
		)
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
			
			if season_day > b and num_fruit_on_tree < 1 and rot > 14 {
					do reset_season;
				}
			}
		}
		
	reflex average_tree_fruiting when: fruit_quality = "good" { // TODO Change back to average
		if (
			((simultaneous_season = true) and (current_date = date(current_date.year, 1,19) or current_date = date(current_date.year, 9,7)))
			or 
			((simultaneous_season = false) and (current_date = date(current_date.year, 11,12)))
		)
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
				
			if season_day > b and num_fruit_on_tree < 1 and rot > 30 {
					do reset_season;
				}
			}
		}
		
	reflex good_tree_fruiting when: fruit_quality = "good" { // TODO change back to good
		if (
			((simultaneous_season = true) and (current_date = date(current_date.year, 2,1) or current_date = date(current_date.year, 9,21)))
			or 
			((simultaneous_season = false) and (current_date = date(current_date.year, 2,1)))
		)
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
			
			if season_day > b and num_fruit_on_tree < 1 and rot > 30 {
					do reset_season;
				}
			}
		}
	
	/* CALCULATE THE EGGS IN A TREE
	 * If the tree is a host tree and has at least 1 fruit or greater on the tree
	 * Then calculate the number of eggs in the tree by summing the fecundity of each fly within the tree
	 * Then create a cohort agent with this number of eggs
	 */
	reflex calc_eggs_in_tree {
		bool goodtree <- fruit_quality !="non" and num_fruit_on_tree > 0;
		if goodtree {
			eggs_in_tree <- fly where (each.myTree = self) sum_of (each.daily_fecundity);
			bool anyeggs <- eggs_in_tree > 0;
			if anyeggs {
				create cohort number: 1 {
					my_larval_tree <- tree(myself.location);
					location <- my_larval_tree.location;
					nb_cohort <- myself.eggs_in_tree;
				}
			}
		}		
	}
	
	/* CALCULATE JUVENILE STAGES
	 * The overall number of eggs, larvae, and pupae in the tree
	 */
	reflex calc_juv_stages_in_tree {
		nb_eggs_in_tree <- cohort where (each.my_larval_tree = self and each.state = "eggs") sum_of (each.nb_cohort);
		nb_larvae_in_tree <- cohort where (each.my_larval_tree = self and each.state = "larvae") sum_of (each.nb_cohort);
		nb_pupae_in_tree <- cohort where (each.my_larval_tree = self and each.state = "pupae") sum_of (each.nb_cohort);
		nb_teneral_in_tree <- cohort where (each.my_larval_tree = self and each.state = "teneral") sum_of (each.nb_cohort);
	    nb_cohorts_inside <- cohort count (each.my_larval_tree = self);
	    nb_flies_inside_tree <- fly count (each.myTree = self);
	}
	
	reflex calc_larval_occupancy {
		capacity <- num_fruit_on_tree * max_larvae_per_fruit;
		}
		
	reflex max_capacity {
 		if max_capacity < capacity {
 			max_capacity <- capacity;
 		}
 	}
		
	reflex calc_percentage_occupacy {
		percent_occupancy <- (occupancy / max_capacity) * 100; // Changed to max_capacity instead of capacity as this was the total number of fruits on the tree. This way it does not go down
 		percent_overcapacity <- percent_occupancy - 100;
		}
	} 
	

species cohort control: fsm {
	int nb_cohort;
	tree my_larval_tree <- one_of(tree);
	string my_larval_host -> my_larval_tree.fruit_quality;
	float larval_mortality;
	float pupal_mortality;
	int days_in_L_stage;
	int days_in_P_stage;
	float larval_development_rate;
	float larval_growth;
	float pupal_development_rate;
	float pupal_growth;
	float age;
	float density_mortality;
	float combined_mortality;
	
	reflex update_age {
		age <- age + (step/86400);
	}

	aspect default {
		draw circle(0.2) color: #lightpink border: #gray;
	}
	
 	action assign_tree_quality {
		if my_larval_host = "poor" {
			egg_mortality <- gauss(0.115, 0.089);  
			larval_mortality <- gauss(0.68, 0.25);  //TODO undo for experiments
			pupal_mortality <- gauss(0.149, 0.152);  
			days_in_L_stage <- round(gauss(13, 3));  
			days_in_P_stage <- round(gauss(13, 2)); 
		}

		if my_larval_host = "average" {
			egg_mortality <- gauss(0.115, 0.089);
			larval_mortality <- gauss(0.526, 0.21); //TODO uno for experiments
			pupal_mortality <- gauss(0.103, 0.10);
			days_in_L_stage <- round(gauss(11, 3));
			days_in_P_stage <- round(gauss(13, 2));
		}

		if my_larval_host = "good" {
			egg_mortality <- gauss(0.115, 0.089);
			larval_mortality <- gauss(0.385, 0.15); //TODO undo for experiments
			pupal_mortality <- gauss(0.057, 0.05);
			days_in_L_stage <- round(gauss(8, 2));
			days_in_P_stage <- round(gauss(13, 2));
		}
	}
	
	/*
	 * Chance of the emerge flies to be male and die 
	 * as males are not the focus of this model
	 */
 	action remove_males {
		if (flip(0.5)) {
			nb_cohort <- nb_cohort - 1;
		}
	}

	state eggs initial: true {		
		enter {
 			do assign_tree_quality;
 		}
		if nb_cohort = 0 {
			do die;
		}
		exit {
			if nb_cohort > 0 {
			loop i from: 1 to: nb_cohort {
					if flip(egg_mortality) {
						nb_cohort <- nb_cohort - 1;
						}
					}
				}           
			}	
		transition to: larvae when: age >= 2.0 {
		}
	}

	state larvae {
		enter {
			if my_larval_tree.nb_larvae_in_tree > my_larval_tree.max_capacity {
				nb_cohort <- my_larval_tree.max_capacity;
			}
			
			ask my_larval_tree {
				occupancy <- myself.nb_cohort + occupancy;
			} 
			
 			larval_development_rate <- 1 / days_in_L_stage;
		}
		
		larval_growth <- larval_growth + larval_development_rate;
		
		if nb_cohort = 0 { 
 				do die;
			}
			
		exit {
			if nb_cohort > 0 {
			loop i from: 1 to: nb_cohort { // The density mortality is based on what has already transitioned to pupae, teneral and emerged. This is to make sure that the initial cohorts make it through the life cycle first. 
				// As there was a tendancy that with very high larvae in a cohort they would end up with nothing and so during the second season in some cases there would be no flies emerging, as all the larvae would die.
				density_mortality <- (my_larval_tree.emerged + my_larval_tree.nb_teneral_in_tree)/(my_larval_tree.max_capacity);
				combined_mortality <- 1-((1-larval_mortality)*(1-density_mortality));
					if flip(combined_mortality) {
						nb_cohort <- nb_cohort - 1;						
						ask my_larval_tree {
							occupancy <- occupancy - 1;
							} 
						}
					}
				}
			} 
		transition to: pupae when: larval_growth >= 1.0;	
	}

	state pupae {
		enter {
 			pupal_development_rate <- 1 / days_in_P_stage;
		}
		
		pupal_growth <- pupal_growth + pupal_development_rate;

		if nb_cohort = 0 {
			do die;
		}
		
		exit {
			if nb_cohort > 0 {
				loop i from: 1 to: nb_cohort {
				if flip(pupal_mortality) {
					nb_cohort <- nb_cohort - 1;
						}
					}
				}
			}
		transition to: teneral when: pupal_growth >= 1.0;
	}

	state teneral final: true {
		enter {
			ask my_larval_tree {
				emerged <- myself.nb_cohort + emerged;
			} 
			do remove_males;
			create fly number: nb_cohort {
				myTree <- myself.my_larval_tree;
				location <- myself.location;
				my_cohort <- myself.name; 
				my_larval_host <- myself.my_larval_host;
				my_larval_mortality_chance <- myself.larval_mortality;
				my_pupal_mortality_chance <- myself.pupal_mortality;
				my_larval_development_time <- myself.days_in_L_stage;
				my_pupal_development_time <- myself.days_in_P_stage;
				// take out the myself.___ for mortality and days in each stage when running sensitivity analysis
 				nb_adults <- nb_adults + 1;
 				nb_adult_total <- nb_adult_total + 1;
				}
			}
			do die;
		}		
	}
	
/*
 * DISPLAY SIMULATION
 */
experiment my_experiment {
	float minimum_cycle_duration <- 0.15;
	output {		
		layout #split;
		display myDisplay {
			grid tree lines: #white refresh: false;
			species fly aspect: default;
			species cohort aspect: default;
		}

		display num_adults {			
			chart "total adults" type: series x_serie_labels: current_date {
				data "adults" value: length(fly) color: #sienna;
				data "good fruit" value: tree where (each.fruit_quality = "good") sum_of (each.num_fruit_on_tree) color: #lightgreen;
				data "average fruit" value: tree where (each.fruit_quality = "average") sum_of (each.num_fruit_on_tree) color: #gold;
				data "poor fruit" value: tree where (each.fruit_quality = "poor") sum_of (each.num_fruit_on_tree) color: #salmon;
			}
		}
	}
}

experiment Benchmarking type:gui benchmark:true  {
}

experiment multiple_maps type: gui {
	action _init_ {
		csv_file map_files <- csv_file("../includes/map_files_11.csv", ",", false);
		matrix data <- matrix(map_files);
		write data;
		loop i from: 0 to: data.rows -1 {  // 19
			create simulation with: [
				grid_map::grid_file(data[0, i]),
				map_name::string(data[1, i]),
				simultaneous_season::bool(data[3,i])
				];
		}
	}
}

//experiment importFromCSV type: gui {
//
//	action _init_ {
//		csv_file size_csv_file <- csv_file("../models/includes/ffas_50to99_2021_10_08.csv", ",", false);
//		matrix data <- matrix(size_csv_file);
//		write data;
//		loop i from: 0 to: data.rows -1 {  // 19
//			create simulation with: [
//				// max_larvae_per_fruit::int(data[0,i]),
//				wing_length::float(data[0,i]),
//				larval_mortality::float(data[1, i]), 
//				pupal_mortality::float(data[2, i]), 
//				days_in_L_stage::int(data[3, i]), 
//				days_in_P_stage::int(data[4, i])
//			];
//		}
//	}
//}

