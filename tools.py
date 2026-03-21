from langchain.tools import tool
import pexpect
import sys
@tool
def create_project(project_name: str) -> str:
    """
    调用ACE工具创建鸿蒙项目。
    项目名称必须以字母开头，只能包含小写字母、数字和下划线(_)，长度1-200。
    Args:
        project_name (str): 项目名称
    """

    target_dir = f"agent_workspace/projects/{project_name}"
    child = pexpect.spawn(f'ace create {target_dir} --template app')
    child.expect('Enter')
    child.sendline('')
    child.expect('Enter')
    child.sendline('')
    child.expect('Enter')
    child.sendline('2')
    child.expect('Please')
    child.sendline('11')
    child.expect('Please')
    child.sendline('1')
    child.expect(pexpect.EOF)
    return f"项目创建完成，路径为: /projects/{project_name}"


@tool
def compile_project(project_name: str) -> str:
    """
    编译鸿蒙项目，并返回所有日志输出
    Args:
        project_name (str): 项目名称
    """

    project_path = f"agent_workspace/projects/{project_name}"
    child = pexpect.spawn(f'bash scripts/compile.sh {project_path}')
    child.expect(pexpect.EOF)
    output = child.before.decode('utf-8', errors='ignore') if isinstance(child.before, bytes) else str(child.before)
    return output
