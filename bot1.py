import logging
from aiogram import Bot, Dispatcher, types
from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.fsm.storage.memory import MemoryStorage
from aiogram.fsm.state import State, StatesGroup
import datetime
BOT_TOKEN = '6977033186:AAG05Licij7gh5Vop-1lSfFrLDY7sCkq6_U'

# Включаем логирование для получения подробной информации о работе бота
logging.basicConfig(level=logging.INFO)

# Создаем экземпляры бота и диспетчера
bot = Bot(token=BOT_TOKEN)
dp = Dispatcher(storage=MemoryStorage())

# Внутренний словарь для хранения встреч
meetings = {}


# Определяем классы для работы с состояниями
class MeetingForm(StatesGroup):
    waiting_for_meeting_time = State()
    waiting_for_cancel_time = State()


# Функция для возврата начальной клавиатуры
def get_main_keyboard():
    return InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text="Записаться на встречу", callback_data="register")],
        [InlineKeyboardButton(text="Посмотреть список", callback_data="view")],
        [InlineKeyboardButton(text="Отменить запись", callback_data="cancel")]
    ])


# Хендлер для команды /start
@dp.message(Command('start'))
async def start(message: types.Message):
    keyboard = get_main_keyboard()
    await message.answer(
        "Добро пожаловать в бот для записи на практические встречи! Вы можете записаться на встречу, просмотреть список запланированных встреч или отменить свою запись. При нажатии на кнопку записи, введите дату и число в предложенном формате (пожалуйста, вводите время с округлением до часа или получаса). Для отмены нажмите на соотвутствующую кнопку и введите дату в нужном формате.",
        reply_markup=keyboard
    )


# Хендлер нажатий на кнопки
@dp.callback_query(lambda c: c.data in ['register', 'view', 'cancel'])
async def process_callback(callback_query: types.CallbackQuery, state: FSMContext):
    if callback_query.data == 'register':
        remove_past_meetings()  # Удаляем прошедшие встречи перед выводом
        await callback_query.message.answer("Текущие записи:")
        await show_meetings(callback_query.message, for_registration=True)
        await callback_query.message.answer(
            "Введите дату и время встречи в формате 'DD-MM-YYYY HH:MM', например '13-09-2024 19:00':")
        await state.set_state(MeetingForm.waiting_for_meeting_time)  # Устанавливаем состояние для записи
    elif callback_query.data == 'view':
        remove_past_meetings()  # Удаляем прошедшие встречи перед выводом
        await show_meetings(callback_query.message)
    elif callback_query.data == 'cancel':
        await callback_query.message.answer(
            "Введите дату и время встречи, с которой хотите отменить запись, в формате 'DD-MM-YYYY HH:MM', например '13-09-2024 19:00':")
        await state.set_state(MeetingForm.waiting_for_cancel_time)  # Устанавливаем состояние для отмены


# Хендлер для регистрации встречи
@dp.message(MeetingForm.waiting_for_meeting_time)
async def register_meeting(message: types.Message, state: FSMContext):
    user = message.from_user
    try:
        user_input = message.text.strip()
        # Изменяем формат на DD-MM-YYYY HH:MM
        meeting_time = datetime.datetime.strptime(user_input, '%d-%m-%Y %H:%M')

        # Проверка, не записан ли пользователь уже на это время
        if meeting_time in meetings and any(user.username == u[0] for u in meetings[meeting_time]):
            await message.answer(f"Вы уже записаны на встречу в {meeting_time.strftime('%d-%m-%Y %H:%M')}.")
        else:
            # Добавляем пользователя в список на это время
            if meeting_time not in meetings:
                meetings[meeting_time] = []
            meetings[meeting_time].append((user.username, user.full_name))

            await message.answer(f'Вы записаны на встречу в {meeting_time.strftime("%d-%m-%Y %H:%M")}!',
                                 reply_markup=get_main_keyboard())

        await state.clear()  # Очищаем состояние
    except ValueError:
        await message.answer('Неверный формат даты. Попробуйте снова.')


# Хендлер для отмены записи
@dp.message(MeetingForm.waiting_for_cancel_time)
async def cancel_meeting(message: types.Message, state: FSMContext):
    user = message.from_user
    try:
        user_input = message.text.strip()
        # Изменяем формат на DD-MM-YYYY HH:MM
        meeting_time = datetime.datetime.strptime(user_input, '%d-%m-%Y %H:%M')

        # Проверяем, записан ли пользователь на это время
        if meeting_time in meetings and any(user.username == u[0] for u in meetings[meeting_time]):
            meetings[meeting_time] = [u for u in meetings[meeting_time] if u[0] != user.username]
            if not meetings[meeting_time]:
                del meetings[meeting_time]
            await message.answer(
                f'Ваша запись на встречу в {meeting_time.strftime("%d-%m-%Y %H:%M")} успешно отменена.',
                reply_markup=get_main_keyboard())
        else:
            await message.answer(f"Вы не были записаны на встречу в {meeting_time.strftime('%d-%m-%Y %H:%M')}.")

        await state.clear()  # Очищаем состояние после отмены записи
    except ValueError:
        await message.answer('Неверный формат даты. Попробуйте снова.')


# Функция для отображения списка встреч
async def show_meetings(message: types.Message, for_registration=False):
    if not meetings:
        if for_registration:
            await message.answer("На данный момент встречи не запланированы.")
        else:
            await message.answer("Список встреч пуст.", reply_markup=get_main_keyboard())
        return

    meeting_list = []
    for time, users in sorted(meetings.items()):
        # Меняем формат отображения на DD-MM-YYYY HH:MM
        meeting_list.append(
            f"{time.strftime('%d-%m-%Y %H:%M')}:\n" + "\n".join(f"- @{user[0]} ({user[1]})" for user in users))

    await message.answer("\n\n".join(meeting_list), reply_markup=get_main_keyboard() if not for_registration else None)


# Функция для удаления прошедших встреч
def remove_past_meetings():
    now = datetime.datetime.now()
    past_meetings = [time for time in meetings if time.date() < now.date()]

    for time in past_meetings:
        del meetings[time]


# Основная функция запуска бота
async def main():
    await bot.delete_webhook(drop_pending_updates=True)
    await dp.start_polling(bot)


if __name__ == '__main__':
    import asyncio

    asyncio.run(main())
