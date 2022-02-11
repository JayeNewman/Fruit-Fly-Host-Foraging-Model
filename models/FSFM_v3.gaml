/**
* Name: FSFMv2
* Based on the internal empty template. 
* Author: newma
* Tags: 
*/


model FSFMv2

/* Insert your model definition here */

global torus: true {
	
	file grid_map <- file("../includes/crop10_land20_trees_10.asc");
	//file grid_map <- file("../includes/single_fruit_5p.asc");
	file proba_stay_tree <- csv_file("../includes/proba_of_staying_tree.csv", ","); 
	//file grid_map;  			/* generic when multiple maps are utilised in the experiments */
	float env_size <- 250 #m;
	geometry map_size <- square(env_size);
	string map_name;			/* For batch experiments that have multiple maps */
 	date starting_date <- date(2020, 8, 24);
 	float step <- 1 #day;
 	int max_flies;
 	int nb_adult_total;
 	int total_lifetime_fecundity;
 	int total_dead;
 	float R0;
 	float ave_daily;

	
	/*** INPUT PARAMETERS ***/
	int nb_fly <- 10;								/* Fly parameter */
	int mature_age <- 10;							/* Fly parameter */
	float sensing_boundary <- 10#m;					/* Fly parameter */
	int number_acceptable_larval_encounters <- 5; 	/* Fly parameter: number of times fruit with larvae can be encountered before they leave the tree */
	bool memory;									/* Fly parameter */
	bool simultaneous_season; 						/* Tree parameter */
	bool poor_first;
	string global_path_file_name <- "../data/results/a1_global.csv";	/* Global parameter naming file */
	
	bool run_experiments <- true;						/* Global parameter: When false sets up model for sensitivity analysis of one fruit host */
	
	// Crop 
	//float pick_percent <- 0.95;
	int season_gap;
	string crop_quality <- "good";
	int crop_max_larvae <- 40;
	
	// Sensitivity parameters
	string sensitivity_fruit <- "good"; 				/* The fruit that the sensitivity analysis will define */ 
	int sensitivity_max_larvae_per_fruit <- 10; 		/* Tree grid parameter for sensitivity analysis in the "run_experiments = false" in the global environment. */ 
	string sensitivity_global_path_file_name <- "../data/results/new_sens_test_global.csv";	/* Global parameter naming file */
 
 	/* Cohort parameters 
 	 * To set for sensitivity analysis "run_experiments = false" in the global environment. */ 
	float sensitivity_larval_mortality; 
	float sensitivity_pupal_mortality;
	int sensitivity_days_in_L_stage;
	int sensitivity_days_in_P_stage;
	float sensitivity_wing_length;  
	
	/* Fly parameters */ 
	int daily_flies;
 	int nb_adults;
		
	/* Weibul function parameters for daily fecundity */ 
 	float beta; 
 	float enya; 
 	float loc;
	float coeff; 
	
 	/* Survival function parameters */ 
 	float xmid;
	float L;
	float E; 
	
	/* Tree parameters 
	 * Parameter values for maximum larvae a single fruit can hold. */ 	
 	int poor_max_larvae <- 5;
	int average_max_larvae <- 15;
	int good_max_larvae <- 45;
	
	/* Fruit per tree over time */ 	
 	float a <- 10.0;  	/* height of curve */ 
 	float b <- 20.0; 	/* centre of the peak */ 
 	float c <- 11.0; 	/* the width of the bell curve */ 
 	 
 	/* Memory affiliation probability to stay */	 
 	matrix proba_stay <- matrix(proba_stay_tree);
	list memory_prob_1 <- proba_stay column_at 1;
	list memory_prob_2 <- proba_stay column_at 2;
	list memory_prob_3 <- proba_stay column_at 3;
	list memory_prob_4 <- proba_stay column_at 4; 
	
 	init {create fly number: nb_fly {
 		    //location <- any_location_in(one_of(host_trees));
 		    location <- any_location_in(one_of(tree));
 		    myTree <- tree closest_to self;
			nb_adults <- nb_adults + 1;
			nb_adult_total <- nb_adult_total + 1;
			age <- 10.0;
			adult_age <- 10.0;
			my_cohort <- "start";
			//my_larval_host <- myTree.fruit_quality;
			my_larval_host <- "good";
			}
		}
 	 
 	/*** REFLEXES ***/
 	
 	reflex count_max {
 		if max_flies < nb_adults {
				max_flies <- nb_adults;
			}
 	}
 	
 	int days_in_non_host;
	int days_in_poor_host;
	int days_in_ave_host;
	int days_in_good_host;
	list<tree> host_trees <- tree where (each.grid_value >= 1);
	int immature_flies_over_time;
	int total_all_fly_fecundity;
	float step_distance;

 	reflex calc_experiment_variables {
		daily_flies <- length(fly);
		immature_flies_over_time <- fly count (each.state = "immature_adult");
		total_all_fly_fecundity <- fly sum_of (each.cumulative_fecundity);
		R0 <- (total_lifetime_fecundity / (total_dead + 1)) with_precision 3; // When the fly dies it gets added to the total_dead and life_time_fecundity
		ave_daily <- (nb_adult_total  / (cycle + 1)) with_precision 3; 
	}

	int total_fruit;
	int total_good_fruit;
 	int total_poor_fruit;
 	int total_average_fruit;
	
	int flies_in_non_host;
	int flies_in_poor_host;
	int flies_in_average_host;
	int flies_in_good_host; 
 	
// 	int total_lf_fecundity_poor;
// 	int total_lf_fecundity_average;
// 	int total_lf_fecundity_good;
 	
 	
 	reflex calc_experimental_variables when: run_experiments = true {
 			total_fruit <- tree sum_of(each.calc_fruit_on_tree);
			total_good_fruit <- tree where (each.fruit_quality = "good") sum_of (each.num_fruit_in_list);
		 	total_poor_fruit <- tree where (each.fruit_quality = "poor") sum_of (each.num_fruit_in_list);
		 	total_average_fruit <- tree where (each.fruit_quality = "average") sum_of (each.num_fruit_in_list);
			
			flies_in_non_host <- tree where (each.fruit_quality = "non") sum_of (each.nb_flies_inside_tree);
			flies_in_poor_host <- tree where (each.fruit_quality = "poor") sum_of (each.nb_flies_inside_tree);
			flies_in_average_host <- tree where (each.fruit_quality = "average") sum_of (each.nb_flies_inside_tree);
			flies_in_good_host <- tree where (each.fruit_quality = "good") sum_of (each.nb_flies_inside_tree);
		 	
//		 	total_lf_fecundity_poor <- fly where(each.my_larval_host = "poor") sum_of (each.cumulative_fecundity);
//		 	total_lf_fecundity_average <- fly where(each.my_larval_host = "average") sum_of (each.cumulative_fecundity);
//		 	total_lf_fecundity_good <- fly where(each.my_larval_host = "good") sum_of (each.cumulative_fecundity);
 	}
 	
 	int sensitivity_flies_in_host;
 	int sensitivity_total_sensitivity_fruit;
 	int sensitivity_total_lf_fecundity;
 	
 	
 	reflex calc_sensitivity_parameters when: run_experiments = false {
 		sensitivity_flies_in_host <- tree where (each.fruit_quality = sensitivity_fruit) sum_of (each.nb_flies_inside_tree);
 	    sensitivity_total_sensitivity_fruit <- tree where (each.fruit_quality = sensitivity_fruit) sum_of (each.num_fruit_in_list);
 	    sensitivity_total_lf_fecundity <- fly where(each.my_larval_host = sensitivity_fruit) sum_of (each.cumulative_fecundity);
		
 	}
	
 	
 	
 	reflex stop_sim when: cycle = 1825 {
 		do pause;
 		//do die;
	}
 	
 	/* SAVING FILES
 	 * Save code at each time step (from .csv file) for the experiments */ 
 	reflex save when: run_experiments = true { 
		save 
		[
		"simulation" + (int(self)), 
		cycle, 
		R0,
		ave_daily,
		memory,
		simultaneous_season, 
		poor_first,
		map_name, 
		nb_adult_total, 
		max_flies, 
		total_fruit, 
		total_good_fruit, 
		total_poor_fruit, 
		total_average_fruit,
		flies_in_good_host, 
		flies_in_average_host, 
		flies_in_non_host, 
		flies_in_poor_host, 
		flies_in_good_host,
		days_in_ave_host, 
		days_in_non_host, 
		days_in_poor_host, 
		days_in_good_host,
		current_date, 
		daily_flies, 
		total_all_fly_fecundity
//		total_lf_fecundity_poor, 
//		total_lf_fecundity_average, 
//		total_lf_fecundity_good 
		]
		to: global_path_file_name type: "csv" header: true rewrite: false;
		
 	}
 	
 	reflex save_sensitivity when: run_experiments = false {
 		save 
		[
		"simulation" + (int(self)), 
		cycle, 
		current_date, 
		R0,
		ave_daily,
		nb_adult_total, 
		max_flies, 
		total_fruit, 
		//total_good_fruit,
		//flies_in_good_host, 
		//days_in_non_host,
		//days_in_good_host,
		daily_flies, 
		//total_all_fly_fecundity,
		sensitivity_max_larvae_per_fruit,
		sensitivity_wing_length, 
		sensitivity_larval_mortality, 
		sensitivity_pupal_mortality,
		sensitivity_days_in_L_stage,
		sensitivity_days_in_P_stage
		//total_lf_fecundity_good
		]
		to: sensitivity_global_path_file_name type: "csv" header: true rewrite: false;
 	}
 	
// 	reflex save_map {
// 		save tree to: "../data/results/map" + map_name + "map.png" type: "image";
// 		save fly to: "../data/results/map" + map_name + "fly.png" type: "image";
// 	}

	reflex cycles { 
 		write 
 		 " cycle: " + cycle	+ " " + int(self)
 		+ " season gap " + season_gap 
		+ " R0 " + R0
		+ " aveDaily " + ave_daily
  		+ " number of flies: " + daily_flies;
 	}
	
 	
	} // end global

grid tree file: grid_map use_regular_agents: false use_neighbors_cache: false use_individual_shapes: false {
	float grid_value <- grid_value;
	rgb color; // <- rgb(int(1 * (percent_occupancy)), 1, int(1 * (percent_occupancy))) update: rgb(int(1 * (percent_occupancy)), 1, int(1 * (percent_occupancy)));
	string fruit_quality;
	float season_day;
	int nb_cohorts_inside;
	int eggs_in_tree;
	int nb_larvae_in_tree;
	int nb_pupae_in_tree;
	int nb_teneral_in_tree;
	int nb_flies_inside_tree;
	int capacity;
	int max_capacity <- 1;
	int larvae_exited_fruit;
	int calc_fruit_on_tree;
	int occupancy;
	float percent_occupancy;
	float percent_overcapacity; 
	bool in_season <- false;
	int days_fruit_fallen;
	int new_daily_fruit;
	list<fruit> list_of_fruit <- list_of_fruit update: list_of_fruit;
	int num_fruit_in_list <- num_fruit_in_list update: length(list_of_fruit);
	int max_larvae_per_fruit;
	int days_between_spray;
	int spray_gap <- 14;
	bool harvested <- false;
	bool is_crop <- false;
	int harvest_day <- 25;
		
	init {
		if grid_value = 0.0 {
			fruit_quality <- "non";
			color <- #white;
		}
		if grid_value = 1.0 {
			fruit_quality <- "poor";
			color <- #salmon;
			max_larvae_per_fruit <- poor_max_larvae; 
		}
		if grid_value = 2.0 {
			fruit_quality <- "average";
			color <- #gold;
			max_larvae_per_fruit <- average_max_larvae;
		}
		if grid_value = 3.0 {
			fruit_quality <- "good";
			color <- #lightgreen;
			max_larvae_per_fruit <- good_max_larvae;
		}
		
		if grid_value = 4.0 {
			is_crop <- true;
			fruit_quality <- crop_quality;
			color <- #black;
			max_larvae_per_fruit <- crop_max_larvae;
		}
		
		if run_experiments = false {
			if grid_value = 0.0 {
			fruit_quality <- "non";
			color <- #white;
			}
			if grid_value = 1.0 {
			fruit_quality <- sensitivity_fruit;
			max_larvae_per_fruit <- sensitivity_max_larvae_per_fruit; 
			}
		}
	}
	
		reflex fruit_cycle when: calc_fruit_on_tree > length(list_of_fruit) {
			if harvested = false {	
				new_daily_fruit <- calc_fruit_on_tree - length(list_of_fruit);
				tree treeRef <- self;
			loop i from: 1 to: new_daily_fruit {
			create fruit number: i {
				fruitTree <- treeRef;
				add self to: treeRef.list_of_fruit;
				
					}
					
				}				
				
			}
				
		}
		
	reflex reduce_fruit when: calc_fruit_on_tree < length(list_of_fruit) {
		fruit oldest_fruit <- first(list_of_fruit);
		ask oldest_fruit {
			remove self from: fruitTree.list_of_fruit;
			available <- false;
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
			max_capacity <- 1;
			days_fruit_fallen <- 0;
			larvae_exited_fruit <- 0;
			harvested <- false;
		}
	
	action start_season {
			season_day <- season_day + (step/86400);
			calc_fruit_on_tree <- round(a * exp(-((season_day - b) ^ 2) / (2 * (c ^ 2))));
			}
	
	reflex limit_to_extended_emergence {
		if season_day > b and length(list_of_fruit)  < 1 {
			days_fruit_fallen <- days_fruit_fallen + 1;
			}
		}
			
 	reflex poor_tree_fruiting_first when: fruit_quality = "poor" and run_experiments = true {
		if (simultaneous_season = true 
			and ((current_date = date(current_date.year, 1,5)) 
				or (current_date = date(current_date.year, 8,25))
			)
		) 
		or (simultaneous_season = false and poor_first = true
			and current_date = date(current_date.year, 8,25)
		)
		or (simultaneous_season = false and poor_first = false
			and current_date = date(current_date.year, 2,1)
		)
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
			if season_day > b and length(list_of_fruit) = 0 and days_fruit_fallen = 14  {
					do reset_season;
					}
				}
		}
		
	reflex average_tree_fruiting when: fruit_quality = "average" and run_experiments = true {
		if simultaneous_season = true 
		and (current_date = date(current_date.year, 1,19) 
			or current_date = date(current_date.year, 9,7)
		)
		or (simultaneous_season = false and current_date = date(current_date.year, 11,12))
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
				
			if season_day > b and length(list_of_fruit) = 0 and days_fruit_fallen = 14 /* and is_crop = false*/ {
					do reset_season;
					}
				}
		}
		
	reflex good_tree_fruiting when: fruit_quality = "good" and run_experiments = true {
		if simultaneous_season = true 
		and (current_date = date(current_date.year, 2,1) 
			or current_date = date(current_date.year, 9,21)
		)
			or (simultaneous_season = false and poor_first = true
				and current_date = date(current_date.year, 2,1)
			)
			or simultaneous_season = false and poor_first = false
				and current_date = date(current_date.year, 8,25)
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
			
			if season_day > b and length(list_of_fruit) = 0 and days_fruit_fallen = 14 /* and is_crop = false*/ {
					do reset_season;
					}
				}
		}
		
		reflex sensitivity_fruiting when: run_experiments = false { 
		if (simultaneous_season = true and (
			current_date = date(current_date.year, 1,5) or 
			current_date = date(current_date.year, 8,25) or
			current_date = date(current_date.year, 2,1) or
			current_date = date(current_date.year, 9,21) or
			current_date = date(current_date.year, 1,19) or
			current_date = date(current_date.year, 9,7)
		)
			or
			
			simultaneous_season = false and (
				current_date = date(current_date.year, 8,25) or
				current_date = date(current_date.year, 8,25) + season_gap #week // or
				// current_date = date(current_date.year, 11,12)
			))
			{
			in_season <- true;
			}
			if in_season = true {
				do start_season;
			
			if season_day > b and length(list_of_fruit) < 1 and days_fruit_fallen > 14 {
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
		bool goodtree <- fruit_quality !="non" and length(list_of_fruit)> 0;
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
		//nb_eggs_in_tree <- cohort where (each.my_larval_tree = self and each.state = "eggs") sum_of (each.nb_cohort);		
		nb_larvae_in_tree <- cohort where (each.my_larval_tree = self and each.state = "larvae") sum_of (each.nb_cohort);
		nb_pupae_in_tree <- cohort where (each.my_larval_tree = self and each.state = "pupae") sum_of (each.nb_cohort);
		nb_teneral_in_tree <- cohort where (each.my_larval_tree = self and each.state = "teneral") sum_of (each.nb_cohort);
	    nb_cohorts_inside <- cohort count (each.my_larval_tree = self);
	    nb_flies_inside_tree <- fly where (each.state = "adult") count (each.myTree = self);
	}
	
	reflex calc_larval_occupancy {
		capacity <- length(list_of_fruit)* max_larvae_per_fruit;
		}
		
	reflex max_capacity {
 		if max_capacity < capacity {
 			max_capacity <- capacity;
 		}
 	}
		
	reflex calc_percentage_occupacy {
		percent_occupancy <- (occupancy / max_capacity) * 100; /* Changed to max_capacity instead of capacity as this was the total number of fruits on the tree. This way it does not go down */ 
 		percent_overcapacity <- percent_occupancy - 100;
		}
		
//	action harvest {
//		if is_crop = true and harvested = false {
// 			num_fruit_in_list <- round(pick_percent*num_fruit_in_list);
// 			calc_fruit_on_tree <- num_fruit_in_list;
// 			harvested <- true;
// 			ask cohort {
// 				if (state = "larvae" or state = "egg") and is_host_crop = true {
// 					if flip(pick_percent) {
// 						larvae_removed <- larvae_removed + 1;
// 						eggs_removed <- eggs_removed + 1;
// 						do die;
// 					}
// 				}
// 			}
// 			ask fruit {
// 				if flip(pick_rate) {
// 				remove self from: fruitTree.list_of_fruit;
// 				available <- false;
// 				}
// 			}
// 		}
// 	}
 	
// 	action spray_crop {
// 		if is_crop = true and in_season = true {
// 			days_between_spray <- days_between_spray + 1;
// 			write "dbs" + days_between_spray;
// 			if days_between_spray = spray_gap {
// 			ask fly overlapping self {
// 				spray_death <- spray_death + 1;
// 				write "sprayed " + spray_death;
// 				do die;
// 				}
//  			days_between_spray <- 0;
// 			}
// 		}
// 	}
 

//	reflex harvest_day when: season_day > harvest_day { // b is the centre of the curve, c is the width of the curve
// 		do harvest;
// 	}
		
//	reflex record_tree when: num_fruit_in_list > 0 or nb_cohorts_inside > 0 {
//		save [string(cycle),
//			host,
//			name,
//			nb_flies_inside_tree,
//			nb_cohorts_inside,
//			nb_larvae_in_tree,
//			nb_pupae_in_tree,
//			nb_teneral_in_tree,
//			location
//			]
//		to: "../data/results/sens_tree.csv" type: "csv" header:true rewrite: false;	
//		
//		} 
	} 

species fruit {
	tree fruitTree;
	int egg_clutch;
	bool larvae_within;
	int egg_day;
	bool available;
	float pick_rate <- 0.95;
	
	init {
		available <- true;
	}
	
	reflex when: egg_clutch > 0 {
		egg_day <- egg_day + 1;
		if egg_day > 2 {
			larvae_within <- true;
		} else {
			larvae_within <- false;
		}
	}
	
	reflex die when: available = false {
		do die;
	}
}

species fly skills: [moving] control: fsm {
	tree myTree <- one_of(tree);  // name of tree
	string current_tree_quality;
 	string my_cohort;
 	string my_larval_host;
 	bool is_larval_crop;
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
	int counter;
	int memory_count;
	string current_affiliated_fruit_host;
	float wing_length;
	float step_distance;
	float searching_boundary;
	float cumulative_distance;								// includes immature cumulative distance
	float imm_cumulative_distance;
	int spray_death;
	
	/* LISTS for evaluating foraging */
	list<tree> fruiting_trees; 								// List of trees fruiting	
	list<tree> distant_fruiting_trees; 						// List of trees fruiting within searching boundary
 	list<tree> affiliated_fruit_within_sensing_boundary;  	// List of affiliated trees: Memory component
 	
 	/* Calculating the functions for 
 	 * distance, survival, mortality, and daily eggs
 	 * These functions are evaluated when called in the model
 	 */
 	float sensitivity_compute_distance_function {return (-2.7+2.7*(sensitivity_wing_length*0.35))*sensing_boundary;}
 	float sensitivity_compute_enya {return ((0.6411*sensitivity_wing_length^2)-(5.0078*sensitivity_wing_length)+35.293);}
 	
 	float compute_distance_function {return (-2.7+2.7*(wing_length*0.35))*sensing_boundary;}
 	float compute_survival_curve {return L / (1 + (exp(E * (adult_age - xmid))));}
	float compute_mortality_chance (float survival_curve) {return (100 - survival_curve) / 100;}
	float compute_enya {return ((0.6411*wing_length^2)-(5.0078*wing_length)+35.293);}
	float compute_coeff {return ((200*enya) - 4600);}
	float compute_daily_eggs {return (round((beta / enya) * (((adult_age - loc) / enya) ^ (beta - 1)) * (exp(-(((adult_age - loc) / enya) ^ beta))) * (coeff)));}	
 	//float compute_sd_of_eggs {return (0.1 * daily_fecundity);} 
 
 
 	/*** STATES ***/  
	state immature_adult initial: true {
		enter {
			ask tree overlapping self {
				myself.myTree <- self;  					/* The name of the tree that it is on */
			} 
			if run_experiments = true {
				if my_larval_host = "poor" {
		 		wing_length <- gauss(4.25, 0.25);
		 			}
		 		if my_larval_host = "average" {
		 		wing_length <- gauss(5.125, 0.25);
		 			}
		 		if my_larval_host = "good" {
		 		wing_length <- gauss(6, 0.25);
		 				}
		 		searching_boundary <- compute_distance_function();	/* The distance function requires wing length to evaluate */
 			}
 		if run_experiments = false {
 			searching_boundary <- sensitivity_compute_distance_function();
 			}
		}
		
		adult_age <- adult_age + (step/86400);
		do update_tree_quality;
		do simple_wander;
		imm_cumulative_distance <- cumulative_distance;
		daily_fecundity <- 0; 

		transition to: adult when: adult_age >= mature_age;
	}


	state adult {
		enter { /* Fixed parameters */
		if my_larval_host = "good" {
 	 		xmid <- 137.0;				/*survival parameters*/
			L <- 100.0;  				/*survival parameters*/
			E <- 0.045; 				/*survival parameters*/
			beta <- 1.7;				/*Daily fecundity parameters*/
 			loc <- 6.0;					/*Daily fecundity parameters*/
 			if run_experiments = true {
 				enya <- compute_enya();		/*Daily fecundity parameters*/
				coeff <- compute_coeff();	/*Daily fecundity parameters*/
 				} 
 			if run_experiments = false {
 				enya <- sensitivity_compute_enya();
 				coeff <- compute_coeff();
 				}
			}
		if my_larval_host = "average" {
 	 		xmid <- 118.5;
			L <- 98.0; 
			E <- 0.04; 
			beta <- 1.7;
 			loc <- 6.0;
			if run_experiments = true {
 				enya <- compute_enya();		/*Daily fecundity parameters*/
				coeff <- compute_coeff();	/*Daily fecundity parameters*/
 				} 
 			if run_experiments = false {
 				enya <- sensitivity_compute_enya();
 				coeff <- compute_coeff();
 				}
		}
		if my_larval_host = "poor" {
 	 		xmid <- 100.0; 
			L <- 96.0;  
			E <- 0.035; 
			beta <- 1.7;
 			loc <- 6.0;
			if run_experiments = true {
 				enya <- compute_enya();		/*Daily fecundity parameters*/
				coeff <- compute_coeff();	/*Daily fecundity parameters*/
 				} 
 			if run_experiments = false {
 				enya <- sensitivity_compute_enya();
 				coeff <- compute_coeff();
 				}
			}
		}
				
		adult_age <- adult_age + (step/86400);
		
		do update_tree_quality;
		do update_lists;
		
		if my_larval_host = "average" {
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
			int daily_fecundity_result <- round(compute_daily_eggs());
			daily_fecundity <- round(daily_fecundity_result);
		}
		
		if my_larval_host = "poor" {
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
			int daily_fecundity_result <- round(compute_daily_eggs());
			daily_fecundity <- round(daily_fecundity_result);
		}
		
		if my_larval_host = "good" {
			mortality_chance <- compute_mortality_chance(compute_survival_curve());
			int daily_fecundity_result <- round(compute_daily_eggs());
			daily_fecundity <- round(daily_fecundity_result);
			}
			
		if daily_fecundity = 0 or (myTree.num_fruit_in_list) = 0 {
 			daily_fecundity <- 0; 			/* there can be a chance that the sd makes the daily fecundity a negative value, so if less than 0, it will default to 0. */
			}
		
		/* The only action for movement. Contains directed and simple wander. */
		do probability_to_stay;

		/* final action to perform as it determines the probability of the flies laying eggs. */ 
		do probability_to_lay_eggs_in_tree; 
		
		/* update number of days in hosts */
		do calculate_days_in_hosts;
		
		/* update cumulative fecundity */
		cumulative_fecundity <- cumulative_fecundity + daily_fecundity;
		transition to: overwintering_adult when: current_date between (date(current_date.year, 4, 14), date(current_date.year, 8,24));
	}

	state overwintering_adult {
		adult_age <- adult_age; // pauses the adult age at this age (adult_age is built into the fecundity function)
 		mortality_chance <- 0.0114;
		daily_fecundity <- 0;
		transition to: adult when: current_date = date(current_date.year, 8, 24);
	}
	
	/*** REFLEXES ***/
	
	/* Save fly information and DIE */
	reflex chance_to_die when: flip(mortality_chance) {
		nb_adults <- nb_adults - 1;
		total_dead <- total_dead + 1;
		total_lifetime_fecundity <- total_lifetime_fecundity + cumulative_fecundity;
		save [string(cycle),
			host,
		//"," + my_larval_host +
		//"," + wing_length +
			sensitivity_wing_length,
			age,
			cumulative_fecundity,
			searching_boundary,
			imm_cumulative_distance,
			cumulative_distance]
		to: "../data/results/new_sens_test_fly.csv" type: "csv" header:true rewrite: false;
		do die; 
	}
	
	/* Update age */
	reflex update_age {
 		age <- age + 1;
 	}
 	
 	/* Memory and affiliation */ 
 	reflex new_affiliated_host when: memory = true and myTree.num_fruit_in_list >= 1 {
		if current_tree_quality = "poor" {
			memory_count <- 2;
			current_affiliated_fruit_host <- "poor";
		}

		if current_tree_quality = "average" {
			memory_count <- 3;
			current_affiliated_fruit_host <- "average";
		}

		if current_tree_quality = "good" {
			memory_count <- 4;
			current_affiliated_fruit_host <- "good";
		}
	}

 	
	/*** ACTIONS ***/
	
	action update_tree_quality {
 	 	current_tree_quality <- myTree.fruit_quality;
 	 }
 	 
 	 action update_lists {  // lists the fruiting trees then shuffles the list for the next action to evaluate. It is also here as this list is accessed by multiple actions
				affiliated_fruit_within_sensing_boundary <- fruiting_trees where (each.fruit_quality = current_affiliated_fruit_host);				
				affiliated_fruit_within_sensing_boundary <- shuffle(affiliated_fruit_within_sensing_boundary);
		}
 
 	 
	/* Movement
	 */
	action simple_wander {
		do wander speed: sensing_boundary #m / #s bounds: circle(sensing_boundary, location); // speed: 1.0 #m / #day // this is the speed that they can move in a day
		location <- any_location_in(circle(sensing_boundary, location));
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
 			fruiting_trees <- tree where (each.num_fruit_in_list>= 1) at_distance sensing_boundary;
 			distant_fruiting_trees <- tree where (each.num_fruit_in_list>= 1) at_distance searching_boundary;
 		
 		/* MOVE within SENSING BOUNDARY */ 
			if !empty(fruiting_trees) {
				do move speed: sensing_boundary #m / #s bounds: circle(sensing_boundary, location);
			     	 	tree maxtree <- fruiting_trees with_max_of (each.grid_value);
						float maxquality <- maxtree.grid_value; 
						tree bestTree <- shuffle(fruiting_trees) first_with (each.grid_value = maxquality);
						location <- bestTree.location;
						step_distance <- myTree distance_to(location);
						cumulative_distance <- cumulative_distance + step_distance;
						myTree <- bestTree;
						location <- myTree.location;
				} 
		
		/* MOVE within SEARCHING BOUNDARY */ 
			if empty(fruiting_trees) and !empty(distant_fruiting_trees) {
				do move speed: searching_boundary #m / #s bounds: circle(searching_boundary, location);
			     	 	tree maxtree <- distant_fruiting_trees with_max_of (each.grid_value);
						float maxquality <- maxtree.grid_value; 
						tree bestTree <- shuffle(distant_fruiting_trees) first_with (each.grid_value = maxquality);
						location <- bestTree.location;
						step_distance <- myTree distance_to(location);
						cumulative_distance <- cumulative_distance + step_distance;
						myTree <- bestTree;
						location <- myTree.location;
				} 
			if empty(fruiting_trees) and empty(distant_fruiting_trees) {
					do simple_wander;
				}
		}
		
	action move_to_affiliated { 
		ask tree overlapping self {
			myself.myTree <- self;
		}
		myTree <- first(affiliated_fruit_within_sensing_boundary);
		location <- myTree.location;
	}
	
	action counter_ticker {
		memory_count <- memory_count - 1;
				counter <- counter + 1;
				if counter > 4 {
					counter <- 5;
					}
				}
	
	action probability_to_stay {
		if memory = true and length(affiliated_fruit_within_sensing_boundary) >= 1 and current_affiliated_fruit_host = "poor" {
			float my_exp_1 <- memory_prob_1 at counter;
			if (flip(my_exp_1)) {
					do move_to_affiliated;
					memory_count <- 3;
					counter <- 1;
			} else {
				do directed_move;
				do counter_ticker;
			}
		}
		if memory = true and length(affiliated_fruit_within_sensing_boundary) >= 1 and current_affiliated_fruit_host = "average" {
			float my_exp_2 <- memory_prob_2 at counter;
			if (flip(my_exp_2)) {
				do move_to_affiliated;
				memory_count <- 3;
				counter <- 1;
				
			} else {
				do directed_move;
				do counter_ticker;
			}
		}
		if memory = true and length(affiliated_fruit_within_sensing_boundary) >= 1 and current_affiliated_fruit_host = "good" {
			float my_exp_3 <- memory_prob_3 at counter;
			if (flip(my_exp_3)) {
	 			do move_to_affiliated;
					memory_count <- 4;
					counter <- 1;
			} else {
				do directed_move;
				do counter_ticker;
				}
			} 
			if memory = true and length(affiliated_fruit_within_sensing_boundary) <= 0 {
				do directed_move;
			}
			if memory = false {
				do directed_move;
			}
		}
 
    /* Probability that the female will lay eggs in fruit in the tree
     */
		action probability_to_lay_eggs_in_tree {
			int larval_encounter <- 0;	
			int sum_list_of_fruit <- length(myTree.list_of_fruit);
			
		if current_tree_quality = "non" {
					prob_lay_eggs <- 0.0;
					daily_fecundity <- 0;
					}
					
	/* POOR fruit egg laying response */
		if sum_list_of_fruit > 0 and current_tree_quality = "poor" {
				int remaining_fecundity <- daily_fecundity;
				
				loop while: remaining_fecundity > 4 {
					list<fruit> the_trees_fruit <- shuffle(myTree.list_of_fruit);
					fruit myFruit <- first(the_trees_fruit);
				if myFruit.larvae_within = false {
					myFruit.egg_clutch <- myFruit.egg_clutch + 5;
					remaining_fecundity <- remaining_fecundity - 5;
					} 
					else { // Does probability to move to affiliated host, moves to that host and then does NOT lay eggs
						larval_encounter <- larval_encounter + 1;
						if larval_encounter > number_acceptable_larval_encounters {
							do probability_to_stay;
							daily_fecundity <- 0;
							remaining_fecundity <- 0;
						}
					}		
				}
			if remaining_fecundity <= 4 {
					list<fruit> the_trees_fruit <- shuffle(myTree.list_of_fruit);
					fruit myFruit <- first(the_trees_fruit);
				if myFruit.larvae_within = false {
					myFruit.egg_clutch <- myFruit.egg_clutch + remaining_fecundity;
					remaining_fecundity <- 0;	
						}	
					}	
				}
				
	/* AVERAGE fruit egg laying response */	
			if sum_list_of_fruit > 0 and current_tree_quality = "average" { 
				int remaining_fecundity <- daily_fecundity;
				float ave_larval_density;
				
				loop while: remaining_fecundity > 4 {
					list<fruit> the_trees_fruit <- shuffle(myTree.list_of_fruit);
					fruit myFruit <- first(the_trees_fruit);
					
					if myFruit.larvae_within = false {
						myFruit.egg_clutch <- myFruit.egg_clutch + 5;
						remaining_fecundity <- remaining_fecundity - 5;
					}

					if myFruit.larvae_within = true { // then probability to lay eggs based on ave_larval_density over the fruit that are occupied
						larval_encounter <- larval_encounter + 1;
						int fruit_occupied <- myTree.list_of_fruit count (myFruit.larvae_within = true);
						ave_larval_density <- myTree.occupancy/fruit_occupied;
						
						prob_lay_eggs <- (1-(ave_larval_density/myTree.max_larvae_per_fruit));
						
							if (flip(prob_lay_eggs)) { 
								myFruit.egg_clutch <- myFruit.egg_clutch + 5;
								remaining_fecundity <- remaining_fecundity - 5;								
								}
							
							if larval_encounter > number_acceptable_larval_encounters {
								do probability_to_stay;
								daily_fecundity <- 0;
								remaining_fecundity <- 0;
							}
						}	
					}
					
				if remaining_fecundity <= 4 {
					list<fruit> the_trees_fruit <- shuffle(myTree.list_of_fruit);
					fruit myFruit <- first(the_trees_fruit);
				if myFruit.larvae_within = false {
						myFruit.egg_clutch <- myFruit.egg_clutch + remaining_fecundity;
						remaining_fecundity <- 0;
						} else {
							if (flip(prob_lay_eggs)) {
								myFruit.egg_clutch <- myFruit.egg_clutch + remaining_fecundity;
								remaining_fecundity <- 0;								
								}
						}	
					}	
				}
				
	/* GOOD fruit egg laying response */	
			if sum_list_of_fruit > 0 and current_tree_quality = "good" {
				int remaining_fecundity <- daily_fecundity;
				
				loop while: remaining_fecundity > 4 {
					list<fruit> the_trees_fruit <- shuffle(myTree.list_of_fruit);
					fruit myFruit <- first(the_trees_fruit);
					myFruit.egg_clutch <- myFruit.egg_clutch + 5;
					remaining_fecundity <- remaining_fecundity - 5;		
				}
			if remaining_fecundity <= 4 {
					list<fruit> the_trees_fruit <- shuffle(myTree.list_of_fruit);
					fruit myFruit <- first(the_trees_fruit);

					myFruit.egg_clutch <- myFruit.egg_clutch + remaining_fecundity;
					remaining_fecundity <- 0;	
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
		//draw circle(searching_boundary) color: #pink empty: true;
		//draw circle(sensing_boundary) color: #lightpink empty: true;
		if state = "immature_adult" 
		{
			color <- #red;
		}
		if state = "adult" {
			color <- #orange;
		} 
		if state = "overwintering_adult" {
			color <- #grey;
		}
		draw square(0.3) color: color;
	}
}


species cohort control: fsm {
	int nb_cohort;
	tree my_larval_tree <- one_of(tree);
	string my_larval_host -> my_larval_tree.fruit_quality;
	bool is_host_crop -> my_larval_tree.is_crop;
	float egg_mortality;
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
	int my_capacity;
	int larvae_removed;
	int eggs_removed;
	
	reflex update_age {
		age <- age + (step/86400);
	}
	
	reflex when: my_larval_tree.in_season = false {
		do die;
	}

	aspect default {
		draw square(0.5) color: #teal;
	}
	
 	action assign_tree_quality {
		if my_larval_host = "poor" {
			egg_mortality <- gauss(0.115, 0.089); 
			if run_experiments = true { 
			larval_mortality <- gauss(0.95, 0.05);  
			pupal_mortality <- gauss(0.30, 0.15);  
			days_in_L_stage <- round(gauss(13, 2));  
			days_in_P_stage <- round(gauss(13, 2)); 
			}
		}

		if my_larval_host = "average" {
			egg_mortality <- gauss(0.115, 0.089);
			if run_experiments = true {
			larval_mortality <- gauss(0.526, 0.21); 
			pupal_mortality <- gauss(0.103, 0.10);
			days_in_L_stage <- round(gauss(11, 2));
			days_in_P_stage <- round(gauss(13, 2));
			}
		}

		if my_larval_host = "good" {
			if run_experiments = true {
			egg_mortality <- gauss(0.115, 0.089);
			larval_mortality <- gauss(0.385, 0.15);
			pupal_mortality <- gauss(0.057, 0.05);
			days_in_L_stage <- round(gauss(8, 0.60));
			days_in_P_stage <- round(gauss(13, 2));
			}
		}
		
		if run_experiments = false {
				larval_mortality <- sensitivity_larval_mortality;
				pupal_mortality <- sensitivity_pupal_mortality;
				days_in_L_stage <- sensitivity_days_in_L_stage;
				days_in_P_stage <- sensitivity_days_in_P_stage;
		}
	}
	
	/*
	 * Chance of the emerge flies to be male and die as males are not the focus of this model
	 */
 	action remove_males {
		if (flip(0.5)) {
			nb_cohort <- nb_cohort - 1;
		}
	}

	state eggs initial: true {
		write "ima egg " + name;		
		enter {
 			do assign_tree_quality;
 			my_capacity <- my_larval_tree.capacity;
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
			write "woop transitioned" ;
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
				/* The density mortality is based on what has already transitioned to teneral and emerged. 
				 This is to make sure that the initial cohorts make it through the life cycle first. 
				 As there was a tendancy that with very high larvae in a cohort they would end up with 
				 nothing and so during the second season in some cases there would be no flies emerging, as all the larvae would die. */
				 
			loop i from: 1 to: nb_cohort { 
				density_mortality <- (my_larval_tree.larvae_exited_fruit)/(my_capacity); 
				combined_mortality <- 1-((1-larval_mortality)*(1-density_mortality)); // includes the larvae that have left the fruit. A density type function
					if flip(combined_mortality) {
						nb_cohort <- nb_cohort - 1;	
						}
					}
				}
				if my_larval_tree.in_season = true {
					ask my_larval_tree {   // this goes here as the total amount of pupae that have emerged from the fruit is a better indivation of larval competition for resources within the fruit
					larvae_exited_fruit <- myself.nb_cohort + larvae_exited_fruit;
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
 				nb_adults <- nb_adults + 1;
 				nb_adult_total <- nb_adult_total + 1;
 				is_larval_crop <- myself.is_host_crop;
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
			grid tree refresh: false;
			species fly aspect: default;
			species cohort aspect: default;
		}

		display num_adults {			
			chart "total adults" type: series x_serie_labels: current_date {
				data "adults" value: length(fly) color: #sienna;
				data "good fruit" value: tree where (each.fruit_quality = "good") sum_of (each.num_fruit_in_list) color: #lightgreen;
				data "average fruit" value: tree where (each.fruit_quality = "average") sum_of (each.num_fruit_in_list) color: #gold;
				data "poor fruit" value: tree where (each.fruit_quality = "poor") sum_of (each.num_fruit_in_list) color: #salmon;
			}
		}
		
		display R0 {
			chart "R0" type: series x_serie_labels: current_date {
				data "R0" value: R0 color: #red;
				
			}
		}
	}
}

experiment sensitivity {
	float minimum_cycle_duration <- 0.0;
	output {		
		layout #split;
//		display myDisplay {
//			grid tree lines: #black ;
//			species fly aspect: default;
//			species cohort aspect: default;
//		}

		display fruit_occupancy {
			chart "fruit_occupancy" type: series x_serie_labels: current_date {
				data "adults" value: length(fly) color: #sienna;
				data sensitivity_fruit value: tree where (each.fruit_quality = sensitivity_fruit) sum_of (each.num_fruit_in_list) color: #lightgreen;
				data "total fruit occupied" value: fruit count(each.larvae_within = true) color: #orange;
				data "flies in trees" value: tree where (each.fruit_quality = sensitivity_fruit) sum_of (each.nb_flies_inside_tree) color: #purple;
				data "R0" value: R0 color: #red;
			}
		}
	}
}

experiment Benchmarking type:gui benchmark:true  {
}

experiment multiple_maps type: gui {
	action _init_ {
		csv_file map_files <- csv_file("../includes/exp_combinations_aV5.csv", ",", false);
		matrix data <- matrix(map_files);
		write data;
		loop i from: 0 to: data.rows -1 {  // 19
			create simulation with: [
				grid_map::grid_file(data[0, i]),
				map_name::string(data[1, i]),
				memory::bool(data[2,i]),
				simultaneous_season::bool(data[3,i]),
				poor_first::bool(data[4,i])
				];
		}
	}
}

experiment csv_import type: gui {

	action _init_ {
		csv_file size_csv_file <- csv_file("../models/includes/SA_0_400_20220208.csv", ",", false);
		matrix data <- matrix(size_csv_file);
		write data;
		loop i from: 0 to: data.rows -1 {  // 19
			create simulation with: [
				sensitivity_wing_length::float(data[0,i]),
				sensitivity_larval_mortality::float(data[1, i]), 
				sensitivity_pupal_mortality::float(data[2, i]), 
				sensitivity_days_in_L_stage::int(data[3, i]), 
				sensitivity_days_in_P_stage::int(data[4, i]),
				season_gap::int(data[5,i])
			];
		}
	}
}