import os
from typing import List
from appdirs import AppDirs
import pathlib

APP_NAME = "Audiograph"
USER_DIR = AppDirs(APP_NAME, "").user_data_dir

def initialiseDirectory():
	if not os.path.isdir(USER_DIR):
		os.mkdir(USER_DIR)

def getFilePath(filename:str = None):
	path = pathlib.Path(USER_DIR).joinpath(pathlib.Path(filename))
	return str(path.absolute())


class Task():
	STOPPED = 0
	RUNNING = 1
	STOPPING = 2

	name: str
	status: str
	total: int # (total > 0): Known completion time, (total = 0): Uknown completion time, (total < 0): No completion time, this is a long running service
	progress: int
	state: int # 0: STOPPED, 1:RUNNING, 2:STOPPING
	

	def __init__(self, name: str, total: int = 0):
		self.name = name
		self.status = ''
		self.total = total
		self.progress = 0
		self.state = self.RUNNING

	def __await__(self):
		while(self.state != self.STOPPED): yield
	
	def isRunning(self) -> bool: return self.state == self.RUNNING
	def setState(self, state: int): self.state = state

tasks = {}

def addTask(task: Task) -> Task:
	if(task.name not in tasks.keys()): tasks[task.name] = task
	return tasks[task.name]

def getTask(taskName: str) -> Task: return tasks[taskName]

async def endTask(taskName: str):
	if(taskName not in tasks.keys()): return
	task: Task = getTask(taskName)
	if(task.isRunning()): task.state = Task.STOPPING # Signal to the task that it should attempt to stop
	await task # Wait for task to stop
	tasks.pop(task.name, None)


class Play():
	timestamp: str
	artistNames: List[str]
	trackTitle: str

	def __init__(self, timestamp: str, artistNames: List[str], trackTitle: str): 
		self.timestamp = timestamp
		self.artistNames = artistNames
		self.trackTitle = trackTitle
	
	def asDict(self) -> dict:
		return {
			"timestamp": self.timestamp,
			"artistNames": self.artistNames,
			"trackTitle": self.trackTitle
		}

class Track():
	title: str
	artistNames: List[str]

	def __init__(self, title: str, artistNames: List[str]):
		self.title = title
		self.artistNames = artistNames
	
	def asDict(self) -> dict:
		return {
			"title": self.title,
			"artistNames": self.artistNames,
		}

class Artist():
	name: str

	def __init__(self, name: str):
		self.name = name
	
	def asDict(self) -> dict:
		return {
			"name": self.name
		}