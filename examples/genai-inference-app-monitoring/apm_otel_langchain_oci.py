"""
Author: Avi Huber
Date: Sep 2024

OTEL instrumentation for the langchain oci classes

This file can be used as an example/base for instrument of langchain packages and other GenAI framworks. 

This instrumentation (apm_otel_langchain_oci.init(tracer)) needs to be called before any calls or initilizations 
of the instrumented classes elsewhere in the app!

Instrumenting these methods (Add other used methods at the main functoin below):
- ChatOCIGenAI.invoke
- OCIGenAIEmbeddings.embed_documents
- OracleVS.similarity_search
- ConversationChain.invoke

spans will include these attributes;
- genAiService: the  OCI genAi service used (ChatOCIGenAI, OCIGenAIEmbeddings, OracleVS)
- genAiPromptLength: the entire promopt length (in chars) used in the ChatOCIGenAI call (include all messages)  
- genAiResponseLenght: chars count 
- genAiModel: model_id

"""

from langchain.chains import ConversationChain

from langchain_community.chat_models import ChatOCIGenAI
from langchain_community.embeddings import OCIGenAIEmbeddings
from langchain_community.vectorstores.oraclevs import OracleVS
from langchain_core.prompt_values import ChatPromptValue

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.trace import SpanKind, Tracer


def lanchain_otel_instrumenter(tracer, func, name=None):
    
    def wrapper(*args, **kwargs):
        class_obj = args[0]
        
        if name:
            genAiService = name
        else:
            genAiService = func.__qualname__.split('.')[0]
        
        genAiPromptLength = None

        if(func.__name__ == "embed_documents"):
            genAiPromptLength = sum(len(s) for s in args[1])
        elif (func.__name__ == "embed_query"):
            genAiPromptLength = len(args[1])
        elif genAiService ==  "ChatOCIGenAI":
            for arg in args:
                if isinstance(arg,ChatPromptValue): 
                    genAiPromptLength = len(arg.to_string())                   
                    break    
        #print(f"Prompt length: {genAiPromptLength}")    

        with tracer.start_as_current_span(func.__name__, kind=SpanKind.CLIENT) as fspan:
            fspan.set_attribute("genAiService", genAiService)
            fspan.set_attribute("Component","apm-otel-langchain")
            if hasattr(class_obj, 'model_id'): # for LLM invocation
                fspan.set_attribute("genAiModel",class_obj.model_id)
            if hasattr(class_obj, "llm") and  hasattr(class_obj.llm, 'model_id'):
                fspan.set_attribute("genAiModel",class_obj.llm.model_id)
            #print(*args)
            result = func(*args, **kwargs) 
            
            if(genAiPromptLength == None and hasattr(result, 'get') ):
                 genAiPromptLength = len(result.get('input','')) + len(result.get('history',''))
            
            if genAiPromptLength:
                fspan.set_attribute("genAiPromptLength", genAiPromptLength)
            
            if not isinstance(result, list):
                if hasattr(result, 'get') and len(result.get('response','')) > 0:
                    fspan.set_attribute("genAiResponseLength", len(result.get('response')))
                elif hasattr(result, 'content'):
                    if isinstance(result.content,str):
                        fspan.set_attribute("genAiResponseLength", len(result.content))
            
            return result
    return wrapper

"""
Instrument the application with OTEL (e.g. use opentelemetry-instrument) and then:
    from opentelemetry import trace
    import apm_otel_langchain_oci
    tracer = trace.get_tracer(__name__)
    apm_otel_langchain_oci.init(tracer)

Alternatively (manual OTEL instrumentation):
    import apm_otel_langchain_oci
    tracer = apm_otel_langchain_oci.init()
    
    The init() function returns the global tracer instance, it should be used to instrument the service call.
    Otherwise calls to LLM, etc., will be reported as individual traces

"""
def init(tracer=None) -> Tracer:
    if tracer == None: 
        otlp_exporter = OTLPSpanExporter()
        # Set up the tracer provider
        trace.set_tracer_provider(TracerProvider())

        # Set up a batch span processor to handle span export
        span_processor = BatchSpanProcessor(otlp_exporter)
        #span_processor = BatchSpanProcessor(ConsoleSpanExporter())
        trace.get_tracer_provider().add_span_processor(span_processor)
        tracer = trace.get_tracer(__name__)

    """
    Methods to instrument. 
    Add/replace with the object.method used in your code 
    Optionally, add a friendlier GenAiService name as the third parameter
    """
    
    ChatOCIGenAI.invoke = lanchain_otel_instrumenter(tracer, ChatOCIGenAI.invoke)
    #ChatOCIGenAI.invoke = lanchain_otel_instrumenter(tracer, ChatOCIGenAI.invoke, "ChatOCIGenAI")
    OCIGenAIEmbeddings.embed_documents = lanchain_otel_instrumenter(tracer, OCIGenAIEmbeddings.embed_documents)
    OracleVS.similarity_search = lanchain_otel_instrumenter(tracer, OracleVS.similarity_search)
    
    ConversationChain.invoke = lanchain_otel_instrumenter(tracer, ConversationChain.invoke, "ChatOCIGenAI")
    
    return tracer
