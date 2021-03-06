import time
import logging
import logging.config
import logging.handlers
from JobMonitor import JobMonitor
from VmssScaler import VmssScaler
import config as config
from ClusterLoadRepository import ClusterLoadRepository
from NodeMonitor import NodeMonitor
import os
import ptvsd

sleeptime = 120
MAX_NODES = 5
WAIT_LOOPS = 5
realPath = os.path.realpath(__file__)
dirPath = os.path.dirname(realPath)

logging.config.fileConfig(dirPath + '/log.conf')
logging.info('starting new session')

#ptvsd.enable_attach("mz_secret", address = ('10.127.91.132', 3000))

# Enable the line of source code below only if you want the application to wait until the debugger has attached to it
#logging.info('Waiting for Debugger')
#ptvsd.wait_for_attach()


vmssScaler = VmssScaler()
scaledowncounter = 0

while True:
    try:
        loadrepo = ClusterLoadRepository(config.DOCUMENTDB_ENDPOINT, 
            config.DOCUMENTDB_AUTHKEY, config.DOCUMENTDB_DATABASE, config.DOCUMENTDB_COLLECTION, config.TENANT_ID)
        

        queues = config.QUEUE_LIST.split(',')
        scalesets = config.VMSS_LIST.split(',')
        i = 0
        for queueName in queues:
           
            logging.info("processing queue " + queueName)
            # cleanup jobs
            logging.info("cleaning jobs")
            jobs = loadrepo.ListActiveJobs(queueName)
            for j in jobs:
                loadrepo.DeleteDocument(j)
            logging.info(str(len(jobs)) + " jobs deleted")

            # cleanup nodes
            logging.info("cleaning nodes")
            nodes = loadrepo.ListActiveNodes(queueName)
            for n in nodes:
                loadrepo.DeleteDocument(n)
            logging.info(str(len(nodes)) + " nodes deleted")

            jobmonitor = JobMonitor(queueName)
            jobs = jobmonitor.GetJobs()
          
            numjobs = len(jobs)
            logging.info(str(numjobs) + " jobs listed")
            for j in jobs:
                loadrepo.UpdateDocument(j._dic)

            # nodemonitor = NodeMonitor(scalesets[i])
            nodes = nodemonitor.GetNodes()
            # numnodes = len(nodes)
            # freenodes = [node for node in nodes if (node.JobStatus == 'free')]
            # numfreenodes = len(freenodes)
            # logging.info(str(len(freenodes)) + " free nodes listed")
            for n in nodes:
                loadrepo.UpdateDocument(n._dic)
            # if ((numjobs >= 10) and (numfreenodes <= 0) and (numnodes <= MAX_NODES)):
            #     vmssScaler.addInstances(scalesets[i], 1)
            # elif ((numjobs >= 1) and (numfreenodes <= 0)):
            #     vmssScaler.scaleTo(scalesets[i], 1)
            # elif (numjobs == 0):
            #     scaledowncounter = scaledowncounter + 1
            #     logging.info("waiting to scale down %d of %d seconds" % scaledowncounter * sleeptime, sleeptime * WAIT_LOOPS)
            #     if (scaledowncounter > WAIT_LOOPS):
            #         scaledowncounter = 0
            #         vmssScaler.scaleTo(scalesets[i], 0)


                
    except Exception:
        logging.exception("message")
    finally:
        logging.info("wait 2mn")
        time.sleep(sleeptime)
