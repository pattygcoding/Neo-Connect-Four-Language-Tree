from pages.connect_four_page import ConnectFourPage


def test_announces_the_opening_player(driver, base_url):
    page = ConnectFourPage(driver, base_url).open()
    assert page.status == "Player X, choose a column."


def test_x_wins_with_a_horizontal_line(driver, base_url):
    page = ConnectFourPage(driver, base_url).open()
    page.play_all([0, 0, 1, 1, 2, 2, 3])
    assert page.status == "Player X wins!"


def test_o_wins_with_a_vertical_line(driver, base_url):
    page = ConnectFourPage(driver, base_url).open()
    page.play_all([0, 1, 0, 1, 6, 1, 6, 1])
    assert page.status == "Player O wins!"


def test_a_full_column_can_no_longer_be_played(driver, base_url):
    page = ConnectFourPage(driver, base_url).open()
    for _ in range(6):
        page.play(0)
    assert page.column_is_disabled(0)


def test_the_reset_button_clears_the_board(driver, base_url):
    page = ConnectFourPage(driver, base_url).open()
    page.play_all([0, 1, 2])
    page.reset()
    assert page.status == "Player X, choose a column."
