# Agent-Based Model (ABM) to Understand Voting Behavior

A simulation model developed using NetLogo v6.3.0 to analyze changes in voting behavior and election results in response to perceived community effects. Model setup is not intended at this time to represent one specific area or population within the US, but rather to symbolize a random selection of eligible US voters. Created as part of the Lafayette College Research Experience for Undergraduates (REU) 2023 site in Mathematics under NSF grant #2150343.

## Prerequisites

- [NetLogo](https://ccl.northwestern.edu/netlogo/)

## Installation

1. Download and install NetLogo from [here](https://ccl.northwestern.edu/netlogo/).
2. Clone this repository.
3. Open the model in NetLogo.

## Usage

1. Open NetLogo.
2. Load the model file 2023.06.26_final.nlogo.
3. Adjust parameters and settings as needed.
4. Click the 'setup' button to initialize the model.
5. Click 'go' to run the simulation timestep.
6. Finally, click the 'elect' button to tally the votes and report election statistics.

## Model Parameters

- **a:** Weights a voter's individual and community-based likelihood to vote.
- **degree-clustered:** Extent to which voters group in echo chambers.
- **party-split:** Breakdown of the electorate by political party.
- **comm-effect:** Community effect, either "Competition" or "Underdog."
- **mean-radius:** Dictates possible values of interaction radii assigned to voters (size of their social circles).

## Results

Results vary greatly depending on model settings. In extreme cases, observable behavior can include "flipped" elections, in which voter turnout is higher among members of the minority party than in the majority party. Our model is intentionally designed to generate results that are consistent with a wide range of outcomes observed in national elections at the state and district levels. Such flexibility in the model construction process allows us to examine which community factors may be driving such discrepancies in election outcome.

## Acknowledgments

- Grace Brophy (Hamilton College), Audrey Rips-Goodwin (University of Kansas), and Lucy Wilson (Bryn Mawr College) for model development.
- Dr. Allison Lewis (Lafayette College), the research mentor and advisor.
- Cooperative Congressional Election Survey ([CCES](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/GDF6Z0)) 2016 for the data used in the model.


