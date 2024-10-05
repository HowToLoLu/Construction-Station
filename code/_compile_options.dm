//#define TESTING				//By using the testing("message") proc you can create debug-feedback for people with this
								//uncommented, but not visible in the release version)

//#define DATUMVAR_DEBUGGING_MODE	//Enables the ability to cache datum vars and retrieve later for debugging which vars changed.

//global pragmas go here
#ifndef OPENDREAM //Opendream does not support these pragmas
#pragma error unused_var
#endif

// Comment this out if you are debugging problems that might be obscured by custom error handling in world/Error
#ifdef DEBUG
#define USE_CUSTOM_ERROR_HANDLER
#endif

#ifdef TESTING
#define DATUMVAR_DEBUGGING_MODE

///Used to find the sources of harddels, quite laggy, don't be surpised if it freezes your client for a good while
//#define REFERENCE_TRACKING
#ifdef REFERENCE_TRACKING

///Used for doing dry runs of the reference finder, to test for feature completeness
///Slightly slower, higher in memory. Just not optimal
//#define REFERENCE_TRACKING_DEBUG

///Run a lookup on things hard deleting by default.
//#define GC_FAILURE_HARD_LOOKUP
#ifdef GC_FAILURE_HARD_LOOKUP
///Don't stop when searching, go till you're totally done
#define FIND_REF_NO_CHECK_TICK
#endif //ifdef GC_FAILURE_HARD_LOOKUP

#endif //ifdef REFERENCE_TRACKING

//#define VISUALIZE_ACTIVE_TURFS	//Highlights atmos active turfs in green
#endif //ifdef TESTING

/// Enables BYOND TRACY, which allows profiling using Tracy.
/// The prof.dll/libprof.so must be built and placed in the repo folder.
/// https://github.com/mafemergency/byond-tracy
//#define USE_BYOND_TRACY

/////////////////////// ZMIMIC

///Enables Multi-Z lighting
#define ZMIMIC_LIGHT_BLEED

/// If this is uncommented, will profile mapload atom initializations
//#define PROFILE_MAPLOAD_INIT_ATOM
#ifdef PROFILE_MAPLOAD_INIT_ATOM
#warn PROFILE_MAPLOAD_INIT_ATOM creates very large profiles, do not leave this on!
#endif

//#define UNIT_TESTS			//If this is uncommented, we do a single run though of the game setup and tear down process with unit tests in between

/// If this is uncommented, we set up the ref tracker to be used in a live environment
/// And to log events to [log_dir]/harddels.log
//#define REFERENCE_DOING_IT_LIVE
#ifdef REFERENCE_DOING_IT_LIVE
// compile the backend
#define REFERENCE_TRACKING
// actually look for refs
#define GC_FAILURE_HARD_LOOKUP
#endif // REFERENCE_DOING_IT_LIVE

#ifdef REFERENCE_TRACKING_FAST
#define REFERENCE_TRACKING
#define REFERENCE_TRACKING_DEBUG
#endif

/// If this is uncommented, force our verb processing into just the 2% of a tick
/// We normally reserve for it
/// NEVER run this on live, it's for simulating highpop only
// #define VERB_STRESS_TEST

#ifdef VERB_STRESS_TEST
/// Uncomment this to force all verbs to run into overtime all of the time
/// Essentially negating the reserve 2%

// #define FORCE_VERB_OVERTIME
#warn Hey brother, you're running in LAG MODE.
#warn IF YOU PUT THIS ON LIVE I WILL FIND YOU AND MAKE YOU WISH YOU WERE NEVE-
#endif

#ifndef PRELOAD_RSC	//set to:
#define PRELOAD_RSC	0 // 0 to allow using external resources or on-demand behaviour;
#endif				// 1 to use the default behaviour;
					// 2 for preloading absolutely everything;

//#define LOWMEMORYMODE
#ifdef LOWMEMORYMODE
	#warn WARNING: Compiling with LOWMEMORYMODE.
	#ifdef FORCE_MAP
	#warn WARNING: FORCE_MAP is already defined.
	#else
	#define FORCE_MAP "runtimestation"
	#endif
#endif

//TODO Remove the SDMM check when it supports 1568
#if !defined(SPACEMAN_DMM) && (DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD) && !defined(FASTDMM)
//Don't forget to update this part
#error Your version of BYOND is too out-of-date to compile this project. Go to https://secure.byond.com/download and update.
#error You need version 514.1583 or higher.
#endif

//Update this whenever the byond version is stable so people stop updating to hilariously broken versions
#define MAX_COMPILER_VERSION 514
#define MAX_COMPILER_BUILD 1589
#if DM_VERSION > MAX_COMPILER_VERSION || DM_BUILD > MAX_COMPILER_BUILD
#warn WARNING: Your BYOND version is over the recommended version (514.1589)! Stability is not guaranteed.
#endif
//Log the full sendmaps profile on 514.1556+, any earlier and we get bugs or it not existing
#if DM_VERSION >= 514 && DM_BUILD >= 1556
#define SENDMAPS_PROFILE
#endif


//Additional code for the above flags.
#ifdef TESTING
#warn compiling in TESTING mode. testing() debug messages will be visible.
#endif

#ifdef CIBUILDING
#define UNIT_TESTS
#endif

#ifdef CITESTING
#define TESTING
#endif

#if defined(UNIT_TESTS)
//Hard del testing defines
#define REFERENCE_TRACKING
#define REFERENCE_TRACKING_DEBUG
#define FIND_REF_NO_CHECK_TICK
#define GC_FAILURE_HARD_LOOKUP
#endif

#ifdef TGS
// TGS performs its own build of dm.exe, but includes a prepended TGS define.
#define CBT
#endif

#if defined(OPENDREAM) && !defined(CIBUILDING)
#error Compiling BeeStation in OpenDream is unsupported due to BeeStation's dependence on the auxtools DLL to function.
#elif !defined(CBT) && !defined(SPACEMAN_DMM) && !defined(FASTDMM) && !defined(CIBUILDING)
#warn Building with Dream Maker is no longer supported and will result in missing interface files.
#warn Switch to VSCode and when prompted install the recommended extensions, you can then either use the UI or press Ctrl+Shift+B to build the codebase.
#endif

#define AUXMOS (world.system_type == MS_WINDOWS ? "auxtools/auxmos.dll" : __detect_auxmos())

/proc/__detect_auxmos()
	var/static/auxmos_path
	if(!auxmos_path)
		if (fexists("./libauxmos.so"))
			auxmos_path = "./libauxmos.so"
		else if (fexists("./auxtools/libauxmos.so"))
			auxmos_path = "./auxtools/libauxmos.so"
		else if (fexists("[world.GetConfig("env", "HOME")]/.byond/bin/libauxmos.so"))
			auxmos_path = "[world.GetConfig("env", "HOME")]/.byond/bin/libauxmos.so"
		else
			CRASH("Could not find libauxmos.so")
	return auxmos_path
