from pathlib import Path
import subprocess
import time
from agent import graph
from utils.graph_visualization import export_graph_visualization


def main():
    export_graph_visualization(graph)



if __name__ == "__main__":
    main()
