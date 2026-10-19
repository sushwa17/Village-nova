"""
VillageNova AI Tool Dispatcher Middleware (Phase 3, Week 8)

Dynamic tool dispatcher mapping Gemini function calls and orchestrator intents
to internal Python specialist functions with latency profiling and execution safety.
"""

from typing import Dict, Any, List, Callable, Optional
import time
import inspect
import logging
from pydantic import BaseModel, Field

from app.agents.tools import TOOL_MANIFEST

logger = logging.getLogger(__name__)


class ToolExecutionResult(BaseModel):
    """Encapsulates the output of a single tool invocation."""
    tool_name: str
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    execution_time_ms: float = 0.0


class ToolDefinition(BaseModel):
    """Schema descriptor for a registered AI tool."""
    name: str
    description: str
    parameters: Dict[str, Any]


class ToolDispatcher:
    """
    Central registry and execution engine for VillageNova AI domain tools.
    """

    _instance: Optional["ToolDispatcher"] = None

    def __init__(self):
        self._registry: Dict[str, Callable[..., Dict[str, Any]]] = {}
        self._manifests: Dict[str, Dict[str, Any]] = {}
        self._load_builtins()

    def _load_builtins(self) -> None:
        """Loads default tools from the TOOL_MANIFEST."""
        for item in TOOL_MANIFEST:
            self.register_tool(
                name=item["name"],
                description=item["description"],
                parameters=item["parameters"],
                callable_func=item["callable"]
            )

    @classmethod
    def get_default(cls) -> "ToolDispatcher":
        """Singleton accessor for the tool dispatcher."""
        if cls._instance is None:
            cls._instance = ToolDispatcher()
        return cls._instance

    def register_tool(
        self,
        name: str,
        description: str,
        parameters: Dict[str, Any],
        callable_func: Callable[..., Dict[str, Any]]
    ) -> None:
        """Registers a function with the dispatcher."""
        self._registry[name] = callable_func
        self._manifests[name] = {
            "name": name,
            "description": description,
            "parameters": parameters
        }
        logger.debug(f"Registered AI tool: {name}")

    def list_tools(self) -> List[ToolDefinition]:
        """Returns all registered tool specifications."""
        return [
            ToolDefinition(
                name=m["name"],
                description=m["description"],
                parameters=m["parameters"]
            )
            for m in self._manifests.values()
        ]

    def get_gemini_tool_declarations(self) -> List[Any]:
        """
        Converts registered tools into google.genai types.Tool and FunctionDeclaration.
        Falls back to raw dicts if google.genai is not available.
        """
        try:
            from google.genai import types
            func_decls = []
            for m in self._manifests.values():
                func_decls.append(
                    types.FunctionDeclaration(
                        name=m["name"],
                        description=m["description"],
                        parameters_json_schema=m["parameters"]
                    )
                )
            return [types.Tool(function_declarations=func_decls)]
        except Exception as e:
            logger.warning(f"Could not build google.genai types.Tool: {e}")
            return list(self._manifests.values())

    async def execute_tool(self, tool_name: str, arguments: Dict[str, Any]) -> ToolExecutionResult:
        """
        Executes a registered tool by name with arguments and timing profiling.
        Supports both sync and async functions safely.
        """
        if tool_name not in self._registry:
            logger.error(f"Attempted to execute unregistered tool: '{tool_name}'")
            return ToolExecutionResult(
                tool_name=tool_name,
                success=False,
                error=f"Tool '{tool_name}' is not registered with the dispatcher.",
                execution_time_ms=0.0
            )

        func = self._registry[tool_name]
        start_time = time.perf_counter()

        try:
            # Filter arguments to match the function's signature
            sig = inspect.signature(func)
            valid_args = {}
            for param_name in sig.parameters:
                if param_name in arguments:
                    valid_args[param_name] = arguments[param_name]

            if inspect.iscoroutinefunction(func):
                result_data = await func(**valid_args)
            else:
                result_data = func(**valid_args)

            elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)
            logger.info(f"Tool '{tool_name}' executed in {elapsed_ms}ms")

            return ToolExecutionResult(
                tool_name=tool_name,
                success=True,
                data=result_data,
                execution_time_ms=elapsed_ms
            )
        except Exception as e:
            elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)
            logger.exception(f"Error executing tool '{tool_name}': {e}")
            return ToolExecutionResult(
                tool_name=tool_name,
                success=False,
                error=str(e),
                execution_time_ms=elapsed_ms
            )


# Global singleton dispatcher instance
dispatcher = ToolDispatcher.get_default()
