package refactoring.before;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Класс, описывающий модель заказа.
 * Учтите, что данный класс предназначен исключительно, чтобы продемонстрировать структуру,
 * которая должна быть переработана с учётом принципа открытости/закрытости.
 */
public class Order {

    /**
     * Список составляющих частей заказа.
     */
    private List<String> lineItems;

    /**
     * Способ доставки заказа.
     */
    private String shipping;

    /**
     * Метод устанавливающий в заказ способ доставки.
     * @param shipping способ доставки заказа.
     */
    public void setShippingType(String shipping) {
        this.shipping = shipping;
    }

    /**
     * Метод определяющий стоимость доставки заказа.
     * Стоит отметить, что именно этот метод мы будем стараться переработать в рамках нашего урока.
     * @return стоимость доставки заказа.
     */
    public BigDecimal getShippingCost() {
        // Бесплатно для больших заказов.
        if ("ground".equals(shipping)) {
            if (getTotal().compareTo(BigDecimal.valueOf(100)) > 0) {
                return BigDecimal.ZERO;
            }
            // 1500 Руб. за килограмм, но не меньше 5000 Руб.
            return BigDecimal.valueOf(Math.max(5000, getTotalWeight().multiply(BigDecimal.valueOf(1500)).doubleValue()));
        }
        if ("air".equals(shipping)) {
            // 3000 Руб. за килограмм при доставке по воздуху, но не меньше 15000 Руб.
            return BigDecimal.valueOf(Math.max(15000, getTotalWeight().multiply(BigDecimal.valueOf(3000)).doubleValue()));
        }
        // Если никакое из условий не подошло, то будет отправлять за 2000 Руб. за килограмм.
        return getTotalWeight().multiply(BigDecimal.valueOf(2000));
    }

    /**
     * Возвращает общую стоимость заказа.
     * Данные метод не имеет ценности в рамках нашей демонстрации - возвращает рандомное значение.
     * @return общая стоимость заказа.
     */
    public BigDecimal getTotal() {
        return BigDecimal.valueOf(100).multiply(BigDecimal.valueOf(Math.random()));
    }

    /**
     * Возвращает общий вес заказа.
     * Данные метод не имеет ценности в рамках нашей демонстрации - возвращает рандомное значение.
     * @return общий вес заказа.
     */
    public BigDecimal getTotalWeight() {
        return BigDecimal.valueOf(100).multiply(BigDecimal.valueOf(Math.random()));
    }

    /**
     * Возвращает дату доставки товара.
     * Данные метод не имеет ценности в рамках нашей демонстрации - возвращает рандомное дату.
     * @return дату доставки товара.
     */
    public LocalDate getShippingDate() {
        return LocalDate.now();
    }

}
