import datetime
import json
import numpy as np
import os
import random
import time
import torch
import torch.nn as nn

from dreamcoder.dreamcoder import explorationCompression
from dreamcoder.utilities import runWithTimeout
from dreamcoder.grammar import Grammar
from dreamcoder.task import NamedVarsTask, Task
from dreamcoder.type import TypeWeights, arrow, tlist
from dreamcoder.recognition import DummyFeatureExtractor, variable
from dreamcoder.domains.arc.primitives import basePrimitives, tcolor, tgrid


def retrieveARCJSONTasks(directory, filenames=None):
    data = []

    for filename in os.listdir(directory):
        if "json" in filename:
            task = retrieveARCJSONTask(filename, directory)
            if filenames is not None:
                if filename in filenames:
                    data.append(task)
            else:
                data.append(task)
    return data


def retrieveARCJSONTask(filename, directory):
    with open(directory + "/" + filename, "r") as f:
        loaded = json.load(f)

    ioExamples = [((example["input"],), example["output"]) for example in loaded["train"]]
    evalExamples = [((example["input"],), example["output"]) for example in loaded["test"]]

    task = Task(filename, arrow(tgrid(tcolor), tgrid(tcolor)), ioExamples, test_examples=evalExamples)
    task.specialTask = ("arc", 5)
    return task


def arc_options(parser):
    # parser.add_argument("--random-seed", type=int, default=17)
    # parser.add_argument("--unigramEnumerationTimeout", type=int, default=3600)
    # parser.add_argument("--firstTimeEnumerationTimeout", type=int, default=1)
    parser.add_argument(
        "-te",
        "--evaluationTimeout",
        default=3.0,
        help="In seconds. default: 3.0",
        type=float,
    )
    parser.add_argument("--featureExtractor", default="dummy", choices=["arcCNN", "dummy"])


class Flatten(nn.Module):
    def __init__(self):
        super(Flatten, self).__init__()

    def forward(self, x):
        return x.view(x.size(0), -1)


def gridToArray(grid):
    temp = np.full((grid.getNumRows(), grid.getNumCols()), None)
    for yPos, xPos in grid.points:
        temp[yPos, xPos] = str(grid.points[(yPos, xPos)])
    return temp


class ArcCNN(nn.Module):
    special = "arc"

    def __init__(self, tasks=[], testingTasks=[], cuda=False, H=64, inputDimensions=25):
        super(ArcCNN, self).__init__()

        self.CUDA = cuda
        self.recomputeTasks = True

        self.outputDimensionality = H

        def conv_block(in_channels, out_channels):
            return nn.Sequential(
                nn.Conv2d(in_channels, out_channels, 3, padding=1),
                # nn.BatchNorm2d(out_channels),
                nn.ReLU(),
                nn.MaxPool2d(2),
            )

        self.gridDimension = 30

        # channels for hidden
        hid_dim = 64
        z_dim = 64

        self.encoder = nn.Sequential(
            conv_block(22, hid_dim),
            conv_block(hid_dim, hid_dim),
            conv_block(hid_dim, hid_dim),
            conv_block(hid_dim, z_dim),
            Flatten(),
        )

    def forward(self, v):
        """ """
        assert v.shape == (v.shape[0], 22, self.gridDimension, self.gridDimension)
        v = variable(v, cuda=self.CUDA).float()
        v = self.encoder(v)
        return v.mean(dim=0)

    def featuresOfTask(self, t):  # Take a task and returns [features]
        v = None
        for example in t.examples:
            inputGrid, outputGrid = example
            inputGrid = inputGrid[0]

            inputTensor = inputGrid.to_tensor(grid_height=30, grid_width=30)
            outputTensor = outputGrid.to_tensor(grid_height=30, grid_width=30)
            ioTensor = torch.cat([inputTensor, outputTensor], 0).unsqueeze(0)

            if v is None:
                v = ioTensor
            else:
                v = torch.cat([v, ioTensor], dim=0)
        return self(v)

    def taskOfProgram(self, p, tp):
        """
        For simplicitly we only use one example per task randomly sampled from
        all possible input grids we've seen.
        """

        def randomInput(t):
            return random.choice(self.argumentsWithType[t])

        startTime = time.time()
        examples = []
        while True:
            # TIMEOUT! this must not be a very good program
            if time.time() - startTime > self.helmholtzTimeout:
                return None

            # Grab some random inputs
            xs = [randomInput(t) for t in tp.functionArguments()]
            try:
                y = runWithTimeout(lambda: p.runWithArguments(xs), self.helmholtzEvaluationTimeout)
                examples.append((tuple(xs), y))
                if len(examples) >= 1:
                    return Task("Helmholtz", tp, examples)
            except:
                continue
        return None

    def featuresOfTasks(self, ts, t2=None):  # Take a task and returns [features]
        """Takes the goal first; optionally also takes the current state second"""
        return [self.featuresOfTask(t) for t in ts]


def main(args):
    """
    Takes the return value of the `commandlineArguments()` function as input and
    trains/tests the model on manipulating sequences of numbers.

    """

    import os

    sort_of_arc_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sortOfARC")
    tasks = retrieveARCJSONTasks(sort_of_arc_dir, None)

    dataDirectory = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ARC/data")

    tasks += retrieveARCJSONTasks(dataDirectory + "/training", None)
    holdoutTasks = retrieveARCJSONTasks(dataDirectory + "/evaluation")

    if args["solver"] == "julia":
        tasks = [NamedVarsTask(t) for t in tasks]
        args["type_weights"] = TypeWeights(
            {
                "list": 1.0,
                "int": 1.0,
                "color": 1.0,
                "bool": 1.0,
                "float": 1.0,
                "grid": 1.0,
            }
        )

    baseGrammar = Grammar.uniform(basePrimitives())
    # print("base Grammar {}".format(baseGrammar))

    timestamp = datetime.datetime.now().isoformat()
    outputDirectory = "experimentOutputs/arc/%s" % timestamp
    os.system("mkdir -p %s" % outputDirectory)

    args.update(
        {
            "outputPrefix": "%s/arc" % outputDirectory,
        }
    )

    featureExtractor = {"dummy": DummyFeatureExtractor, "arcCNN": ArcCNN}[args.pop("featureExtractor")]

    explorationCompression(baseGrammar, tasks, featureExtractor=featureExtractor, testingTasks=[], **args)
