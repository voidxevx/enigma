import sys
import os
import subprocess
import shutil
from enum import Enum, auto

LIB_DIRECTORY = "./zig-out/lib"
TARGET_DIRECTORY = "./bin"
RUST_TARGET_DIRECTORY = "./target/debug"

if os.name == "nt":
    BINARY_FILE_EXTENSION = ".exe"
else:
    BINARY_FILE_EXTENSION = ""

BINARY_FILE_NAME = "enigma"

def step_build() -> bool:
    print("\x1b[32mBuilding...\x1b[0m")
    if subprocess.call(["zig", "build"]) != 0:
        print("\x1b[31mFailed to build Zig\x1b[0m")
        return False

    # TODO: copy so files to target
    for file in os.listdir(LIB_DIRECTORY):
        src_path = os.path.join(LIB_DIRECTORY, file)
        target_path = os.path.join(TARGET_DIRECTORY, file)
        rust_target_path = os.path.join(RUST_TARGET_DIRECTORY, file)

        if os.path.isfile(src_path):
            shutil.copy2(src_path, target_path)
            shutil.copy2(src_path, rust_target_path)

    if subprocess.call(["cargo", "zigbuild"]) != 0:
        print("\x1b[31mFailed to build Rust\x1b[0m")
        return False

    binary_src_path = os.path.join(RUST_TARGET_DIRECTORY, BINARY_FILE_NAME + BINARY_FILE_EXTENSION)
    binary_target_path = os.path.join(TARGET_DIRECTORY, BINARY_FILE_NAME + BINARY_FILE_EXTENSION)
    if os.path.isfile(binary_src_path):
        shutil.copy2(binary_src_path, binary_target_path)

    return True

def run_step() -> bool:
    print("\x1b[32mRunning...\x1b[0m")
    binary_path = os.path.join(TARGET_DIRECTORY, BINARY_FILE_NAME + BINARY_FILE_EXTENSION)
    return subprocess.call([binary_path]) == 0


def test_step() -> bool:
    print("\x1b[32mTesting...\x1b[0m")
    if subprocess.call(["zig", "build", "test"]) != 0:
        print("\x1b[31mZig tests failed!\x1b[0m")
        return False
    if subprocess.call(["cargo", "test"]) != 0:
        print("\x1b[31mRust tests failed!\x1b[0m")
        return False

    return True

class Step(Enum):
    BUILD = 0
    TEST = 1,
    RUN = 2,

steps: list[Step] = []

for arg in sys.argv:
    match arg:
        case "build":
            steps.append(Step.BUILD)
        case "test":
            steps.append(Step.TEST)
        case "run":
            steps.append(Step.RUN)


for step in steps:
    match step:
        case Step.BUILD:
            if not step_build():
                print("\x1b[31mBuild Failed!\x1b[0m")
                break

        case Step.RUN:
            if not run_step():
                print("\x1b[31mRun step Failed!\x1b[0m")
                break

        case Step.TEST:
            if not test_step():
                print("\x1b[31mTests failed!\x1b[0m")
                break

print("\x1b[32mFinished!\x1b[0m")