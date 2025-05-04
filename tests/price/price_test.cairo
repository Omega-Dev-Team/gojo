use satoru::price::{price::{Price, PriceImpl, PriceTrait}};
use zeroable::Zeroable;

#[test]
fn price_struct_creation(){
    let mut price_struct = Price{max: 40, min: 5};
    assert( (price_struct.min, price_struct.max) == (5, 40), 'Mismatched values' );

    price_struct.min = 12;
    price_struct.max = 68;
    
    assert((price_struct.min, price_struct.max) == (12, 68), 'Mismatched values');

}

#[test]
#[should_panic()]
fn price_struct_creation_failure(){
    let mut price_struct = Price {max: 11, min: 5};
    assert( ( price_struct.min, price_struct.max ) == (7, 11), 'Test passed');

    assert( (price_struct.min, price_struct.max) == (6, 88), 'Test passed' );
}

#[test]
fn mid_price_test_pass(){
    let mut price_struct = Price {max: 12, min: 8};
    assert( price_struct.mid_price() == 10, 'Not mid_price');

    price_struct.max = 16;
    price_struct.min = 7;

    assert( price_struct.mid_price() == 11, 'Wrong mid_price');

    price_struct.max = 15;
    price_struct.min = 11;

    assert( price_struct.mid_price() == 13, 'mid_price fail');
}

#[test]
#[should_panic]
fn mid_price_test_fail(){
    let mut price_struct = Price { min: 4, max: 15};

    assert( price_struct.mid_price() == 10, 'floor value fail' );

    price_struct.min = 12;
    price_struct.max = 33;

    assert( price_struct.mid_price() == 23, 'Floor value fail');

}

#[test]
fn pick_price_test_pass(){
    let price_struct = Price {min: 15, max: 87};

    assert(price_struct.pick_price(true) == 87, 'expected max value');
    assert( (price_struct.pick_price(false), price_struct.pick_price(true)) == (15, 87), 'Mismatched values');

    assert( price_struct.pick_price(true) != 15, 'Wrong value');
    assert( price_struct.pick_price(false) != 98, 'Wrong value');
}

#[test]
#[should_panic]
fn pick_price_test_fail(){
    let mut price_struct = Price {min: 20, max: 58};

    assert(price_struct.pick_price(true) == 12, 'Any value accepted');
    assert( (price_struct.pick_price(false), price_struct.pick_price(true)) == (23, 78), 'Any value accepted');

    price_struct.min = 18;
    price_struct.max = 28;

    assert( price_struct.pick_price(false) == 20, 'No new value');
    assert(price_struct.pick_price(true) == 58, 'No new value');

}

#[test]
fn pick_price_for_pnl_test_pass() {
    let mut price_struct = Price {min: 11 , max: 45};
    
    assert(price_struct.pick_price_for_pnl(is_long: true, maximize: true) == 45, 'Expected price_struct.max');
    assert(price_struct.pick_price_for_pnl(is_long: true, maximize:false) == 11, 'Expected price_struct.min');

    assert(price_struct.pick_price_for_pnl(is_long: false, maximize:true) == 11,'Expected price_struct.min');
    assert(price_struct.pick_price_for_pnl(is_long: false, maximize:false) == 45, 'Expected price_struct.max');

    price_struct.min = 4;
    price_struct.max = 23;

    assert(price_struct.pick_price_for_pnl(is_long: true, maximize: true) == 23, 'Expected price_struct.max');
    assert(price_struct.pick_price_for_pnl(is_long: true, maximize: false) == 4, 'Expected price_struct.min');

    assert(price_struct.pick_price_for_pnl(is_long: false, maximize: true)== 4, 'Expected price_struct.min');
    assert(price_struct.pick_price_for_pnl(is_long: false, maximize: false) == 23, 'Expected price_struct.max');

}



#[test]
#[should_panic]
fn pick_price_for_pnl_test_fail() {
    let mut price_struct = Price {min: 11 , max: 45};
    
    assert(price_struct.pick_price_for_pnl(is_long: true, maximize: true) == 23, 'Expected price_struct.max');
    assert(price_struct.pick_price_for_pnl(is_long: true, maximize:false) == 4, 'Expected price_struct.min');

    assert(price_struct.pick_price_for_pnl(is_long: false, maximize:true) == 2,'Expected price_struct.min');
    assert(price_struct.pick_price_for_pnl(is_long: false, maximize:false) == 8, 'Expected price_struct.max');

    price_struct.min = 4;
    price_struct.max = 23;

    assert(price_struct.pick_price_for_pnl(is_long: true, maximize: true) == 11, 'Expected price_struct.max');
    assert(price_struct.pick_price_for_pnl(is_long: true, maximize:false) == 15, 'Expected price_struct.min');

    assert(price_struct.pick_price_for_pnl(is_long: false, maximize:true) == 3,'Expected price_struct.min');
    assert(price_struct.pick_price_for_pnl(is_long: false, maximize:false) == 11, 'Expected price_struct.max');
}

#[test]
fn zero_test_pass(){
    let  zero_struct = Zeroable::<Price>::zero();
    let price_struct = Price {min: 0, max: 0};
    
    assert((zero_struct.min, zero_struct.max) == (0, 0), 'Expected (0,0)');
}


#[test]
#[should_panic]
fn zero_test_fail(){
    let  zero_struct = Zeroable::<Price>::zero();
    let price_struct = Price {min: 12, max: 14};
    
    
    assert((zero_struct.min, zero_struct.max) == (price_struct.min, price_struct.max), 'min or max is not zero');
    assert((zero_struct.min,zero_struct.max) != (0,0), 'Should be zero tuple');
}



#[test]
fn  is_zero_test_pass() {
    let mut price_struct = Price {min: 0, max: 0 };

    assert(price_struct.is_zero() == true, 'min and max are not zero');

    price_struct = Price {min: 1, max: 12};
    assert(price_struct.is_zero() == false, 'One value is not zero');

    price_struct = Price {min: 0, max: 10};
    assert(price_struct.is_zero() == false, 'One value is not zero');
}


#[test]
#[should_panic]
fn  is_zero_test_fail() {
    let mut price_struct = Price {min: 0, max: 0 };

    assert(price_struct.is_zero() == false, 'min and max should be zero');

    price_struct = Price {min: 1, max: 12};
    assert(price_struct.is_zero() == true, 'All values should be zero');

    price_struct = Price {min: 0, max: 10};
    assert(price_struct.is_zero() == true, 'All values should be zero');
}



#[test]
fn is_non_zero_test_pass() {
    let mut price_struct = Price {min: 1, max: 0};

    assert(price_struct.is_non_zero() == true, 'min and max are zero');

    price_struct = Price {min:0, max:0};
    
    assert(price_struct.is_non_zero() == false, 'min and max are zero');
}


#[test]
#[should_panic]
fn  is_non_zero_test_fail() {
    let mut price_struct = Price {min: 0, max: 0 };

    assert(price_struct.is_non_zero() == true, 'All values are zero');

    price_struct = Price {min: 1, max: 12};
    assert(price_struct.is_non_zero() == false, 'Expected true');

    price_struct = Price {min: 0, max: 10};
    assert(price_struct.is_zero() == false, 'Expected true');
}
