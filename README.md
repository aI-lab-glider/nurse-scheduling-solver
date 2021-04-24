# Nurse Scheduling Solver

![Codecov](https://img.shields.io/codecov/c/github/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-solver) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://project-summer-ai-lab-glider.github.io/nurse-scheduling-problem-solver/dev/) [![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)

The solver is part of the system created for [Fundacja Rodzin Adopcyjnych](https://adopcja.org.pl), the pre-adoption center in Warsaw (Poland). The project was set during Project Summer [AILab](http://www.ailab.agh.edu.pl) & [Glider](http://www.glider.agh.edu.pl) 2020 event and has been under intensive development since then.

The system aims to improve the operations of the foundation automatically, forming effective work schedules for employees. So far, this has been manually done in spreadsheets, which is a tedious job.

The migration to the system is realized by importing a plan from an Excel spreadsheet, which is the form, the foundation adopted earlier. If this is impossible, the application can be incorporated without previous schedules.

In the current version work plans are adjusted based on the legislation of Polish Labour Code for medical staff.

The system comprises three components which can be found on two GitHub repositories:
 - *web/desktop application* provides the environment for convenient preparation of work schedules (detailed information [here](https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-frontend))
 - *solver* responsible for finding issues in work schedules and fixing them automatically (not introduced yet)
 - *backend* ([Genie framework](https://genieframework.com/)) links the functions of both previous components

This repository contains the solver and the backend.