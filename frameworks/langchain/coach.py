import os

from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

SYSTEM = (
    "You are a concise Connect Four coach. Reply in a single short sentence, "
    "naming one column number and the reason."
)

HUMAN = (
    "It is player {player}'s turn. The board is:\n{board}\n"
    "Which column (1-7) should they play, and why?"
)


def build_coach(model=None, temperature=0.2):
    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", SYSTEM),
            ("human", HUMAN),
        ]
    )
    llm = ChatOpenAI(
        model=model or os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
        temperature=temperature,
    )
    return prompt | llm | StrOutputParser()


def suggest_move(board, coach=None):
    chain = coach or build_coach()
    return chain.invoke({"player": board.current_player, "board": board.render()})
