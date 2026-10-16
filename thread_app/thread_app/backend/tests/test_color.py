from app.color import ciede2000, snap, contrast_warning

def test_sharma_reference_pairs():
    assert abs(ciede2000((50,2.6772,-79.7751),(50,0,-82.7485)) - 2.0425) < 1e-3
    assert abs(ciede2000((50,2.5,0),(73,25,-18)) - 27.1492) < 1e-3
    assert abs(ciede2000((50,2.5,0),(50,3.1736,0.5854)) - 1.0000) < 1e-3

def test_snap_skips_out_of_stock():
    th=[{'id':1,'sample_hex':'#800000','type':'normal','in_stock':0},
        {'id':2,'sample_hex':'#701010','type':'normal','in_stock':1}]
    assert snap('#800000', th)['thread']['id']==2

def test_contrast():
    assert contrast_warning('#c0392b','#b03a2e')['too_close']
    assert not contrast_warning('#d4af37','#5b1a18')['too_close']
