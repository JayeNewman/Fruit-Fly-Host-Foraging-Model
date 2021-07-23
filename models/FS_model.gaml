/**
* Name: FSmodel
* Based on the internal empty template. 
* Author: newma
* Tags: 
*/


model FSmodel

/* Insert your model definition here */

global torus: true {
	file proba_stay_tree <- csv_file("../includes/proba_of_staying_tree.csv", ","); 
	file grid_map <- file("../includes/single_fruit_5p.asc");
	//file grid_map;
	geometry shape <- envelope(grid_map);
	string map_name;
 	date starting_date <- date(2020, 8, 24);
 	int nb_fly <- 5;
 	int immigration_number <- 1;
 	int max_flies <- 0;
 	int nb_adult_total <- 0;
 	int flies_over_time;
	float step <- 1 #day;
	float sensing_radius <- 10#m;
	float speed <- 1.0;
	bool memory <- false;
	bool simultaneous_season <- false;
	bool immigration;	
 
 	// Cohort parameters
 	float egg_mortality;
	float larval_mortality <- 0.15;
	float pupal_mortality <- 0.0;
	float days_in_L_stage <- 6.0;
	float days_in_P_stage <- 11.0;
	
	// Fly parameters
	int mature_age <- 10;
	float days_in_IM_stage;
 	int nb_adults <- 0;
	int nb_cohort;
	float mortality_chance;
	float wing_length <- 7.0;
	float foraging_radius;
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
 	float a <- 5.0;  // height of curve
 	float b <- 80.0; // centre of the peak
 	float c <- 30.0; // the width of the bell curve
 	
 	int max_larvae_per_fruit <- 100;
 	
 	//REFLEXES
 	
 	reflex immigrate when: immigration = true { 		
 		if current_date = date(current_date.year, 9,1) {
		create fly number: immigration_number {
			my_cohort <- "immigrated";
			my_larval_host <- "average";
			}
		}
 	}
 	
 	reflex count_max {
 		if max_flies < nb_adults {
				max_flies <- nb_adults;
			}
 	}
 	
 	reflex flies_over_time {
		flies_over_time <- length(fly);
		immature_flies_over_time <- length(fly where (each.state = "immature_adult"));
		total_all_fly_fecundity <- fly sum_of (each.cumulative_fecundity);
		host_good_emergence <- length(fly where (each.my_larval_host = "good"));
		host_average_emergence <- length(fly where (each.my_larval_host = "average"));
		host_poor_emergence <- length(fly where (each.my_larval_host = "poor"));
	}

	int flies_in_non_host -> tree where (each.fruit_quality = "non") sum_of (each.nb_flies_inside_tree);
	int flies_in_poor_host -> tree where (each.fruit_quality = "poor") sum_of (each.nb_flies_inside_tree);
	int flies_in_average_host -> tree where (each.fruit_quality = "average") sum_of (each.nb_flies_inside_tree);
	int flies_in_good_host -> tree where (each.fruit_quality = "good") sum_of (each.nb_flies_inside_tree); //// This code is for saving time step values during the batch runs
	int total_fruit -> tree sum_of(each.num_fruit_on_tree);
	int total_good_fruit -> tree where (each.fruit_quality = "good") sum_of (each.num_fruit_on_tree);
 	int total_poor_fruit -> tree where (each.fruit_quality = "poor") sum_of (each.num_fruit_on_tree);
 	int total_average_fruit -> tree where (each.fruit_quality = "average") sum_of (each.num_fruit_on_tree);
 	int total_lf_fecundity_poor <- fly where(each.my_larval_host = "poor") sum_of (each.cumulative_fecundity);
 	int total_lf_fecundity_average <- fly where(each.my_larval_host = "average") sum_of (each.cumulative_fecundity);
 	int total_lf_fecundity_good <- fly where(each.my_larval_host = "good") sum_of (each.cumulative_fecundity);
 	
 	reflex stop_sim when: cycle = 1095 {
 		do pause;
 		do die;
	}
 	
 	// Batch experiment code (from .csv file)
 	reflex save {
		save 
		[
		"simulation" + (int(self)+1), cycle, // memory, simultaneous_season, map_name, 
		nb_adult_total, max_flies, total_fruit, max_larvae_per_fruit, //total_good_fruit, total_poor_fruit,
		flies_in_average_host, flies_in_non_host, //flies_in_poor_host, flies_in_good_host,
		days_in_ave_host, days_in_non_host, //days_in_poor_host, days_in_good_host,
		current_date, flies_over_time, wing_length, larval_mortality, total_all_fly_fecundity, immature_flies_over_time
		//host_good_emergence, host_average_emergence, host_poor_emergence,
		//total_lf_fecundity_poor, total_lf_fecundity_average, total_lf_fecundity_good, 
		]
		to: "../data/results/GOOD_TEST_sensitivity.csv" type: "csv" header: true rewrite: false;
 	}
 	
// 	reflex save_fly when: cycle >= 0 {
//	 	ask fly {
//			// save the values of the variables name, speed and size to the csv file; the rewrite facet is set to false to continue to write in the same file
//			save [
//			"simulation" + (int(self)+1), cycle, name, current_date, 
//				xmid, E, L, state, age, my_larval_host, wing_length, 
//				daily_fecundity, cumulative_fecundity, 
//				sensing_radius, foraging_radius, step_distance, cumulative_distance
//			] to: "../data/results/fly_agent_good_sensitivity.csv" type: "csv" rewrite: false;
//	 	}
// 	}
 	
// 	reflex save_map {
// 		save tree to: "../data/results/map" + map_name + ".png" type: "image";
// 	}

	reflex cycles {
 		write "" + int(self) +
 		" date: " + current_date + " cycle: " + cycle + " fruit: " + total_fruit + " max larvae: " + max_larvae_per_fruit + " wing length: " + wing_length +
		" l mort: " + larval_mortality + " number of flies: " + flies_over_time;
 	}
	
 	init {create fly number: nb_fly {
 		    location <- any_location_in(one_of(host_trees));
 		    myTree <- self.location;
			nb_adults <- nb_adults + 1;
			nb_adult_total <- nb_adult_total + 1;
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
	int daily_fecundity;
	int cumulative_fecundity;
	float age; 
 	float adult_age;
	float mortality_chance;
	float prob_lay_eggs;
	int counter <- 0;
	string current_affiliated_fruit;
	int memory_count;
	float sensing_radius <- 10#m;
	float step_distance;
	float foraging_radius;
	float cumulative_distance;

	//float wing_length; // TODO input actual data on wing_length into the model (currently has dummy data)
	
	/*
	 * LISTS for evaluating foraging
	 */
	list<tree> fruiting_trees; // where the trees are fruiting			
 	list<tree> larval_density; // a list of only trees where larvae are below the density_threshold. Directed move parameters
 	list<tree> affiliated_fruit_within_radius;
 	
 	/*
 	 * Calculating the functions for 
 	 * distance, survival, mortality, and daily eggs
 	 */
 	float compute_distance_function {
 		return (-2.7+2.7*(wing_length*0.35))*sensing_radius;
 	}
 	
 	float compute_survival_curve {
		return L / (1 + (exp(E * (adult_age - xmid))));
	}
	
	float compute_mortality_chance (float survival_curve) {
		return (100 - survival_curve) / 100;
	}
	
	float compute_enya {
		return ((0.6411*wing_length^2)-(5.0078*wing_length)+35.293);
	}
	
	float compute_coeff {
		return ((200*enya) - 4600);
	}
	
	float compute_daily_eggs {
		return (round((beta / enya) * (((adult_age - loc) / enya) ^ (beta - 1)) * (exp(-(((adult_age - loc) / enya) ^ beta))) * (coeff)));
	}
 	
 	float compute_sd_of_eggs {
 		return (0.1 * daily_fecundity);
	} 
	
	// STATES 
	state immature_adult initial: true {
		enter {
			if my_larval_host = "poor" {
 		//wing_length <- gauss(5, 0.25);
 			}
 		if my_larval_host = "average" {
 		//wing_length <- gauss(5.5, 0.25);
 			}
 		if my_larval_host = "good" {
 		//wing_length <- gauss(6, 0.25);
 			}
 		foraging_radius <- compute_distance_function();	
		}
		
		adult_age <- adult_age + (step/86400);
		
		do simple_wander;
		daily_fecundity <- 0;
 		ask tree overlapping self {
			myself.myTree <- self;
		}

		transition to: adult when: adult_age >= mature_age;
	}

	state adult {
		
		adult_age <- adult_age + (step/86400);
		if my_larval_host = "average" {
 	 		xmid <- 118.5;
//			L <- 98.0;
//			E <- 0.04; 
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
		}
		
		if my_larval_host = "poor" {
 	 		xmid <- 100.0; 
			//L <- 96.0;  // fixed at poor
			//E <- 0.035; // fixed at poor
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
		}
		
		if my_larval_host = "good" {
 	 		xmid <- 137.0;
			L <- 100.0;
			E <- 0.045; 
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
		}
		
		// The only action for movement
		do probability_to_stay;
		
		// Daily Fecundity depending on larval host
		if age > 7.0 {
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
 		ask tree overlapping self {
			myself.myTree <- self;
		}
	
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
		save (string(cycle) + "," + host + "," + name + "," + my_larval_host + "," + age + "," + adult_age + "," + wing_length + "," + cumulative_fecundity + "," + foraging_radius + "," + cumulative_distance)
		to: "../data/results/fly_file_GOOD_TEST.csv" type: "csv" header:true rewrite: false;
		do die;
	}
	
	/* Update age
	 */
	reflex update_age {
 		age <- age + 1;
 	}
 	
 	/* Update my tree quality
 	 */
 	 reflex update_tree_quality {
 	 	current_tree_quality <- myTree.fruit_quality;
 	 }
 	
	/* Memory and affiliation
	 */ 
 	reflex new_affiliated_host when: memory = true and (memory_count <= 0) and (myTree.num_fruit_on_tree >=1) {
		if current_tree_quality = "poor" {
			memory_count <- 2;
			current_affiliated_fruit <- "poor";
		}

		if current_tree_quality = "average" {
			memory_count <- 3;
			current_affiliated_fruit <- "average";
		}

		if current_tree_quality = "good" {
			memory_count <- 4;
			current_affiliated_fruit <- "good";
		}
	}

	// ACTIONS 
	/*
	 *  Movement
	 */

	action simple_wander {
		do wander speed: foraging_radius #m / #s bounds: circle(foraging_radius, location); // speed: 1.0 #m / #day // this is the speed that they can move in a day
		location <- any_location_in(circle(foraging_radius, location));
		step_distance <- myTree distance_to(location);
		cumulative_distance <- cumulative_distance + step_distance;
 		} 	
 		
 	/* 
	 * Directed move is based on OPTIMAL FORAGING / BEST CHOICE BEHAVIOUR. 
	 * The highest grid value within the sensing radius is selected
	 */	
 	
	action directed_move {
		ask tree overlapping self {
			myself.myTree <- self;
			}
			fruiting_trees <- tree at_distance sensing_radius where (each.num_fruit_on_tree >= 1);
		    
			if !empty(fruiting_trees) {	
				do move speed: sensing_radius #m / #s bounds: circle(sensing_radius, location);
			    tree maxtree <- (fruiting_trees) with_max_of (each.grid_value);
			    float maxquality <- maxtree.grid_value; 
				tree bestTree <- one_of(fruiting_trees where(each.grid_value = maxquality));
				location <- bestTree.location;
				step_distance <- myTree distance_to(location);
				cumulative_distance <- cumulative_distance + step_distance;
				} else {
					do simple_wander;
				}
		}

	action move_to_affiliated {
		ask tree overlapping self {
			myself.myTree <- self;
		}
		fruiting_trees <- tree at_distance sensing_radius where (each.num_fruit_on_tree >= 1);
		affiliated_fruit_within_radius <- fruiting_trees where (each.fruit_quality = current_affiliated_fruit);
		if !empty(affiliated_fruit_within_radius) {
			myTree <- one_of(fruiting_trees);
			location <- myTree.location;
		} else {
			do directed_move;
		}
	}
	
	action probability_to_stay {
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
 
    /*
     * Probability that the female will lay in the tree depending on the percent capacity of cumulative eggs over time.
     */
	
		action probability_to_lay_eggs_in_tree {
		if myTree.num_fruit_on_tree > 0 and current_tree_quality = "non" or 
				(current_tree_quality = "poor" and myTree.percent_occupancy > 10) {
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
	
	/* 
	 * Calculate the days spent in each host if not overwintering
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

	/*
	 * Fly agent aesthetics
	 */
	aspect default {
		draw circle(foraging_radius) color: #pink empty: true;
		draw circle(0.25) color: #sienna;
	}
}

grid tree file: grid_map {
	float grid_value <- grid_value;
	string fruit_quality;
	float season_day;
	float days_since_harvest;
	int nb_cohorts_inside; //<- length(cohort inside self);
	int eggs_in_tree;
	int nb_eggs_in_tree;
	int nb_larvae_in_tree;
	int nb_pupae_in_tree;
	int nb_tenoral_in_tree;
	int nb_flies_inside_tree -> length(fly inside self);
	int capacity;
	int max_capacity <- 1;
	int emerged;
	int num_fruit_on_tree;
	//int max_larvae_per_fruit; // undo for experiments
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
			fruit_quality <- "good";  // change back to poor
			color <- #salmon;
			//max_larvae_per_fruit <- 5;
		}
		if grid_value = 2.0 {
			fruit_quality <- "average";
			color <- #gold;
			//max_larvae_per_fruit <- 10;
		}
		if grid_value = 3.0 {
			fruit_quality <- "good";
			color <- #lightgreen;
			//max_larvae_per_fruit <- 20;
		}
	}
 
 	/*
 	 * SEASONS
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
			}
	
	reflex reduce_fruit {
		if simultaneous_season = true {
			a <- 12.5;
		}
	}
	
	reflex limit_to_extended_emergence {
		if season_day > b and num_fruit_on_tree < 1 {
			rot <- rot + 1;
			}
		}
			
 	reflex poor_tree_fruiting when: fruit_quality = "good" { // change back to poor
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
			
			if season_day > b and num_fruit_on_tree < 1 and rot > 30 {
					do reset_season;
				}
			}
		}
		
	reflex average_tree_fruiting when: fruit_quality = "good" { // Change back to average
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
		
		reflex good_tree_fruiting when: fruit_quality = "good" { // change back to good
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
	
	/*
	 * CALCULATE THE EGGS IN A TREE
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
	
	/*
	 * CALCULATE JUVENILE STAGES
	 * The overall number of eggs, larvae, and pupae in the tree
	 */
	reflex calc_juv_stages_in_tree {
		nb_eggs_in_tree <- cohort where (each.my_larval_tree = self and each.state = "eggs") sum_of (each.nb_cohort);
		nb_larvae_in_tree <- cohort where (each.my_larval_tree = self and each.state = "larvae") sum_of (each.nb_cohort);
		nb_pupae_in_tree <- cohort where (each.my_larval_tree = self and each.state = "pupae") sum_of (each.nb_cohort);
		nb_tenoral_in_tree <- cohort where (each.my_larval_tree = self and each.state = "emerge") sum_of (each.nb_cohort);
	    nb_cohorts_inside <- length(cohort where (each.my_larval_tree = self));
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
	float larval_development_rate;
	float larval_growth;
	float pupal_development_rate;
	float pupal_growth;
	float age;
	float density_mortality;
	float combined_mortality;
	int potential_pupae;
	
	reflex update_age {
		age <- age + (step/86400);
	}

	aspect default {
		draw circle(0.2) color: #lightpink border: #gray;
	}
	
 	action assign_tree_quality {
		if my_larval_host = "poor" {
			egg_mortality <- gauss(0.115, 0.089);  
			//larval_mortality <- gauss(0.68, 0.25);  
			//pupal_mortality <- gauss(0.149, 0.152);  
			//days_in_L_stage <- gauss(13.0, 3.0);  
			//days_in_P_stage <- gauss(13.0, 2.0); 
		}

		if my_larval_host = "average" {
			egg_mortality <- gauss(0.115, 0.089);
			//larval_mortality <- gauss(0.526, 0.21);
			//pupal_mortality <- gauss(0.103, 0.10);
			//days_in_L_stage <- gauss(11.0, 3.0);
			//days_in_P_stage <- gauss(13.0, 2.0);
		}

		if my_larval_host = "good" {
			egg_mortality <- gauss(0.115, 0.089);
			//larval_mortality <- gauss(0.385, 0.15);
			//pupal_mortality <- gauss(0.057, 0.05);
			//days_in_L_stage <- gauss(8.0, 2.0);
			//days_in_P_stage <- gauss(13.0, 2.0);
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
		transition to: larvae when: age >= 2.0;
	}

	state larvae {
		enter {
			if my_larval_tree.nb_larvae_in_tree > my_larval_tree.max_capacity {
				nb_cohort <- my_larval_tree.max_capacity;
			}
			
			ask my_larval_tree {
				occupancy <- myself.nb_cohort + occupancy;
			} 
			
			do assign_tree_quality;
 			larval_development_rate <- 1 / days_in_L_stage;
		}
		larval_growth <- larval_growth + larval_development_rate;
		
		if nb_cohort = 0 { 
 				do die;
			}
			
		exit {
			if nb_cohort > 0 {
			loop i from: 1 to: nb_cohort {
				density_mortality <- (my_larval_tree.emerged + my_larval_tree.nb_pupae_in_tree + my_larval_tree.nb_tenoral_in_tree)/(my_larval_tree.max_capacity);
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
		transition to: pupae when: larval_growth >= 1.0 {
		}
	}

	state pupae {
		enter {
			do assign_tree_quality;
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
		transition to: tenoral when: pupal_growth >= 1.0;
	}

	state tenoral final: true {
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
			grid tree lines: #white;
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

experiment multiple_maps type: gui {
	action _init_ {
		csv_file map_files <- csv_file("../includes/map_files_11.csv", ",", false);
		matrix data <- matrix(map_files);
		write data;
		loop i from: 0 to: data.rows -1 {  // 19
			create simulation with: [
				grid_map::grid_file(data[0, i]),
				map_name::string(data[1, i]),
				memory::bool(data[2,i]),
				simultaneous_season::bool(data[3,i])
				];
		}
	}
}

experiment importFromCSV type: gui {

	action _init_ {
		csv_file size_csv_file <- csv_file("../includes/ave_fruit_and_size.csv", ",", false);
		matrix data <- matrix(size_csv_file);
		write data;
		loop i from: 0 to: data.rows -1 {  // 19
			create simulation with: [
				max_larvae_per_fruit::int(data[0,i]),
				wing_length::float(data[1,i]),
				larval_mortality::float(data[2, i]), 
				pupal_mortality::float(data[3, i]), 
				days_in_L_stage::int(data[4, i]), 
				days_in_P_stage::int(data[5, i])
			];
		}
	}
}

