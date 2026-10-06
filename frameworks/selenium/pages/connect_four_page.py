from selenium.webdriver.common.by import By


class ConnectFourPage:
    URL = "http://localhost:5173/"

    STATUS = (By.CSS_SELECTOR, "[role='status']")
    COLUMNS = (By.CSS_SELECTOR, "#columns button")
    RESET = (By.CSS_SELECTOR, "#reset")

    def __init__(self, driver, base_url=None):
        self.driver = driver
        self.base_url = base_url or self.URL

    def open(self):
        self.driver.get(self.base_url)
        return self

    @property
    def status(self):
        return self.driver.find_element(*self.STATUS).text

    def play(self, column):
        self.driver.find_elements(*self.COLUMNS)[column].click()
        return self

    def play_all(self, columns):
        for column in columns:
            self.play(column)
        return self

    def reset(self):
        self.driver.find_element(*self.RESET).click()
        return self

    def column_is_disabled(self, column):
        return not self.driver.find_elements(*self.COLUMNS)[column].is_enabled()
