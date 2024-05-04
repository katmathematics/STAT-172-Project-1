# Analyzing Hazard Data for Optimal Expansion of the U.S. Electrical Grid
- ### Contributors: [Katja Mathesius](https://github.com/katmathematics), [Caleb Patterson](https://www.linkedin.com/in/caleb-patterson-39bb7b227/), [Hmingthan Zama](https://www.linkedin.com/in/hmingthan-zama-b124191a4/)
- ### Active Development Period: February 2024 - May 2024
- ### Motivating Source: (STAT 190) Case Studies in Data Analytics

## Description
One of the major problems facing energy companies is how to balance expanding their energy grid with the many risks that pose a threat to the grid. Across any region of interest for expansion is an existing pattern of demand for energy. However, there is also a complex system of threats to the grid, such as lightning and wildfires, that occur more or less frequently in certain locations. This project analyzes data regarding outages, energy demand, common risks to the energy grid from the contiguous United States and creates predictive models for discerning where in the future is likely to be low risk, high demand locations to put new grid resources

## Data Sets Used
- [Bonneville Power Administration Outage Data](https://transmission.bpa.gov/Business/Operations/Outages/default.aspx)
- [Hourly Interchange Data](https://www.eia.gov/electricity/gridmonitor/dashboard/electric_overview/US48/US48)
- [National Centers for Environmental Information Lightning Data](https://www.ncei.noaa.gov/pub/data/swdi/database-csv/v2/)
- [2.3 Million Wildfires](https://www.kaggle.com/datasets/braddarrow/23-million-wildfires?resource=download)

---

## Instructions
After downloading this repository, the following instructions are designed to help you navigate and run the repository contents

### Language Requirements
The following languages are required to run this repository:
- __R__ >= __4.4.0__
    - If you don't already have RStudio installed, install the RStudio IDE to avoid having to reconfigure directory instructions
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
    4. After downloading the interchange files for all available years, go over to where the repository is downloaded and create a new folder titled __"interchange_data"__ under __"data/web_data/"__
    5. Move all of the downloaded interchange .csv files into the new "interchange_data" folder. The project should now have access to the data utilized for interchange forecasting.

### Instructions for running the project

#### Quick Start - Dashboard

#### Quick Start - Analysis
After downloading the two manual data files, the quickest and most straight forward way to run the analysis is through the included runner file "Runner.R"

1. Open the __STAT-190-Project-1.RProj__ file that was included in the repository in RStudio
2. From R studio, open __Runner.R__
3. Towards the top of the file, find the binary variable __RUN_INTERACTIVELY__ and set it to TRUE
    - __RUN_INTERACTIVELY__ controls whether or not you wish to go through an interactive, command-line based process for selecting which files you wish to run. If you haven't run the project before we recommend going through this process to better understand what goes into the running of this project. However, if you already know which files you want to run, you may set __RUN_INTERACTIVELY__ to FALSE and then manually configure the binary variables that determine which files should be run.
4. Run the entire R project file. After going through the interactive configuration process on the command line, any files you selected will be run. If you agreed to run every file, which is recommended for first time set up, the code may take up to an hour to execute

#### Detailed Instructions

---
- _ReadMe File written by: Katja Mathesius_
- _This repository will not be supported after its active development period. Please respect the creators time and refrain from contacting the creators with any questions or bug reports found in this repository_
