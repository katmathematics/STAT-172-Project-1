# Analyzing Hazard Data for Optimal Expansion of the U.S. Electrical Grid
- ### Contributors: [Katja Mathesius](https://github.com/katmathematics), [Caleb Patterson](https://www.linkedin.com/in/caleb-patterson-39bb7b227/), [Hmingthan Zama](https://www.linkedin.com/in/hmingthan-zama-b124191a4/)
- ### Active Development Period: February 2024 - May 2024
- ### Motivating Source: (STAT 190) Case Studies in Data Analytics as supervised by [Lendie R. Follett](https://www.drake.edu/zimpleman/about/facultystaff/facultybydepartment/lendierfollett/)

## Description
One of the major problems facing energy companies is how to balance expanding their energy grid with the many risks that pose a threat to the grid. Across any region of interest for expansion is an existing pattern of demand for energy. However, there is also a complex system of threats to the grid, such as lightning and wildfires, that occur more or less frequently in certain locations. This project analyzes data regarding outages, energy demand, common risks to the energy grid from the contiguous United States and creates predictive models for discerning where in the future is likely to be low risk, high demand locations to put new grid resources

## Data Sets Used
- [Bonneville Power Administration Outage Data](https://transmission.bpa.gov/Business/Operations/Outages/default.aspx)
- [U.S. Energy Information Administration Hourly Interchange Data](https://www.eia.gov/electricity/gridmonitor/dashboard/electric_overview/US48/US48)
- [National Centers for Environmental Information Lightning Data](https://www.ncei.noaa.gov/pub/data/swdi/database-csv/v2/)
- [U.S. Department of Agriculture 2.3 Million Wildfires](https://www.kaggle.com/datasets/braddarrow/23-million-wildfires?resource=download)

---

## Set-Up Instructions
After downloading this repository, the following instructions are designed to help you navigate and run the repository contents

### Language Requirements
The following languages are required to run this repository:
- __R__ = __4.3.2__
    - If you don't already have RStudio installed, install the RStudio IDE to avoid having to reconfigure directory instructions
    - This repository currently has a dependency on mapstools, which is not supported under R 4.4.0 or later. Please revert to an older version of R to run this project.
- __Python__ >= __3.12.3__


### Manual Data Requirements
In order to successfuly run this analysis code, 2 data sets must be manually downloaded. This section provides instructions on where to access them and how to add them to the project.

- [2.3 Million Wildfires](https://www.kaggle.com/datasets/braddarrow/23-million-wildfires?resource=download)
    1. Go to the 2.3 Million Wildfires dataset on Kaggle, as created by Karen C. Short and uploaded to Kaggle by Brad Darrow, and download the provided zipped data file
    2. Extract the .sqlite file contained in the downloaded zip file
    3. Navigate to where the repository is downloaded. We now must create a series of folders in order to store the data.
        1. At the top level of the repository, create a folder titled __"data"__
        2. Within the __"data"__ folder create a folder titled __"web_data"__
        3. Within the __"web_data"__ folder create a folder titled __"wildfire_data"__
    4. Move the .sqlite file into the newly created "wildfire_data" folder. The project should now have access to the data utlized for wildfire forecasting.
- [Hourly Interchange Data](https://www.eia.gov/electricity/gridmonitor/dashboard/electric_overview/US48/US48)
    1. Go to the U.S. Energy Information Administration's Hourly Electric Grid Monitor Dashboard and click the "Download Data" button
    2. Select the "Six-Month Files" tab at the top. You should now see a screen with a bunch of tabs for years, and links to download .csv files for "balance" "interchange" or "subregion"
    3. Go through each year and download any .csv files labeled as "interchange"
    4. After downloading the interchange files for all available years, go over to where the repository is installed and create a new folder titled __"eia_data"__ under __"data/web_data/"__
    5. Inside the __"eia_data"__ folder, create a folder titled __"interchange"__
    6. Move all of the downloaded interchange .csv files into the new "interchange_data" folder. The project should now have access to the data utilized for interchange forecasting.

## Instructions for Running the Project

### Quick Start - Analysis
After downloading the two manual data files, the quickest and most straight forward way to run the analysis is through the included runner file "Runner.R"

1. Open the __STAT-190-Project-1.RProj__ file that was included in the repository in RStudio
2. From R studio, open __Runner.R__
3. Towards the top of the file, find the binary variable __RUN_INTERACTIVELY__ and set it to TRUE
    - __RUN_INTERACTIVELY__ controls whether or not you wish to go through an interactive, command-line based process for selecting which files you wish to run. If you haven't run the project before we recommend going through this process to better understand what goes into the running of this project. However, if you already know which files you wish to run, you may set __RUN_INTERACTIVELY__ to FALSE and then manually configure the binary variables that determine which files should be run.
4. Run the entire R project file. After going through the interactive configuration process on the command line, any files you selected will be run. If you agreed to run every file, which is recommended for first time set up, the code may take up to an hour to execute

### Detailed Instructions
This section contains a detailed breakdown of the repository's contents. Its contents is intended to serve as a guide for anyone interested in getting into the specific details of this project. 

#### File Structure 
Below is what the structure of the repository looks like after running the code and generating the additional "data" folder and its subdirectories
```
├───data
│   ├───cleaned_data
│   ├───compressed_raw_data
│   ├───model_data
│   ├───prediction_data
│   └───web_data
│       ├───bpa_data
│       ├───eia_data
│       │   └───interchange
│       ├───ncei_data
│       └───wildfire_data
├───data_visualizations
│   ├───BPA_visualizations
│   ├───data_exploration
│   └───model_visualization
├───Python
└───R
    ├───Models
    └───Model_Data_Examination
```
#### Description of the folders
##### /data/
The data folder contains a nested directory of data files. This folder does not come automatically with the repository, and must be created through a combination of code and manual effort.
- /cleaned_data/
    - This folder contains cleaned versions of the files either from __web_data__ or __compressed_raw_data__ depending on if the data required an appending step to make it into a single data frame before manipulation. "Cleaning" includes various manipulations such as removing bad data and rewriting variables to make them more workable to the analysis code
- /compressed_raw_data/
    - This folder contains versions of the data stored in the web_data folders that have been appended together so they can be cleaned and handled as one data set by the analysis code. No cleaning work has been done on this data aside from the act of stitching all the data files together.
- /model_data/
    - This folder contains a data frame that unifies all the other data files . Two files get written here by the cleaning code: "ModelDataLeftOuter.csv" and "ModelDataComplete.csv". "ModelDataLeftOuter.csv" is the result of performing a left outer join on the clean data files, which results in rows still being included even if certain files lack values for them. This is best if you want to not lose any data. "ModelDataComplete.csv" contains only fully complete rows created from merging the data, also called an inner join, and is best if you want a seemless experience while running modeling code.
- /prediction_data/
   - Prediction data is data that is output as a result of the models and can be used for visualizing findings about how the model did or conclusions about where to put grid resources 
- /web_data/
    - This folder stores a series of sub-directories that contain raw data taken directly from their respective sources. No manipulations have been performed on this data.
#### /data_visualizations/
The data_visualizations folder stores image files for data visualizations generated by the analysis code. Visualizations are sorted into folders based off of what they are a visualization of.
#### /Python/
The Python folder stores the Python code for the project. As the project is primarily written in R, there are only 2 code files that can be found in this directory, "GetData.py" and "DataHelper.py"
- GetData.py
    - Web scraping code for data from the Bonneville Power Administration and National Centers for Environmental Information. Running this file from the command line allows the user to optionally pass either "bpa" or "ncei" as the first argument in order to retrieve its respective data, and then additionally optionally pass a local directory to write the file to. If run without arguments it will retrieve both the data from the Bonneville Power Administration and National Centers for Environmental Information and write them to their respective default directories.
- DataHelper.py
    - A helper file for GetData.py. Contains code for helping save files and scraping data from the web
##### /R/
The R folder stores all R code for the project. This is the primary folder for the project and contains most of the files a user would want to interact with, either for simply running the code to get its output or for getting into the fine-grained details of it. The following is a breakdown of what specific files do:
- Runner.R
    - This file serves as an easy way to run every file in the project sequentially. It contains an interactive configuration mode to guide those just getting started with the project, but this interactive feature can also be disabled through a binary variable within the file and the control variables for which files to run configured quickly to run sets of project files quickly and easily. Notably this file goes through all the other R scripts in the project, as well as having code for executing the python scraper file in order to pull data from the National Centers for Environmental Information. 
- BPAScrapingCleaning.R
   - This file scrapes data from the Bonneville Power Administration website pertaining to power outages and cleans it for use in the BPA analysis file. BPA Outage data is not used in the final predictive model, but was instead used to inform common causes of power outages.
- BPAAnalysis.R
   - Creates histograms of causes of power outages, broken down by how long the outage was, and seperated into two seperate plots based on how common the outages are. It should be noted that the causes we choose to analyze in this project: wildfires, and lightning strikes, are considered "uncommon" causes of outages, but are still the analysis choice as the "common" causes are largely planned, part failure, or forseeably human caused outages. 
- EIACleaning.R
    - Cleans interchange data from the U.S. Energy Information Administration. Interchange is a stand in for grid demand, and represents how much energy regions imported or exported. Regions that import a lot of energy have a defict in supply, and thus high demand. Interchange is cleaned by taking as the average of the interchange over the month to reduce the data scope and in order to see what typically demand looks like for a region in any given month. 
- EIAAnalysisl.R
   - Generates a visualization of what the average interchange value in regions looks like.
- NCEILightningCleaning.R
   - Cleans the lightning data from the National Centers for Environmental Information. Lightning is cleaned by converting the longitude/latitude coordinates of lightning strikes to a total over the counties that lightning strikes occured in by month. 
- WildfireCleaning.R
   - Processes the wildfire data in order to clean data that is originally on a daily longitude/latitude scale into a sum over a state per month in order to be more easily processed on weaker hardware
- WildfireAnalysis.R
   -  Generates a series of cursory visualizations into what the wildfire data looks like
- MergeDataSources.R
    - This cleaning file combined the cleaned data for monthly average interchange, monthly lightning strike occurences, and monthly wildfire occurences into one singular data file. It modifies the data such that each row contains the total lightning and wildfire occurences for the state for the month, as well as the average interchange for the region the state is located in for the month.
- CompleteAnalysis.R
    - This file is itself a runner file for all the modeling code in the project. It first runs a series of files for creating analysis plots of the data used in modeling. These visualization files can be found within the __"/Model_Data_Examinations/"__ folder within "/R/". It then assembles and evaluates 3 different types of models (exponential smoothing, linear regression, and decision tree regressor) for each of the 3 data sources, as well as 1 "model" for the unified data that utilizes a combination of the best predictive models for each data source. These modeling files can be found within the __"/Models/"__ folder within "/R/".
- Nav.R
    - This file builds a dashboard using [shiny](https://en.wikipedia.org/wiki/Shiny_(software)) for easy visualization of the predictions generated by this project 

---
- _ReadMe File written by: Katja Mathesius_
- _This repository will not be supported after its active development period. Please respect the creators time and refrain from contacting the creators with any questions or bug reports found in this repository_
