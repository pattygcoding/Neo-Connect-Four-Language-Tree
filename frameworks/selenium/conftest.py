import os

import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options


@pytest.fixture(scope="session")
def base_url():
    return os.environ.get("BASE_URL", "http://localhost:5173/")


@pytest.fixture
def driver():
    options = Options()
    if os.environ.get("HEADLESS", "1") == "1":
        options.add_argument("--headless=new")
    options.add_argument("--window-size=1024,768")

    browser = webdriver.Chrome(options=options)
    browser.implicitly_wait(5)

    yield browser
    browser.quit()
